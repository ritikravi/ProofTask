import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/llm.dart';
import 'package:receipts/core/models.dart';
import 'package:receipts/core/url_guard.dart';
import 'package:receipts/features/verification/commit_fetcher.dart';
import 'package:receipts/features/verification/url_fetcher.dart';
import 'package:receipts/features/challenges/challenge_generator.dart';
import 'package:receipts/features/tasks/task_list_screen.dart';
import 'package:receipts/features/verification/verification_service.dart';

class _FakeLlm implements LlmProvider {
  _FakeLlm(this.verdict, this.confidence);
  final String verdict;
  final double confidence;

  @override
  Future<String> complete({
    required String system,
    required String user,
    double temperature = 0.9,
  }) async => 'Roasted.';

  @override
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  }) async => {
    'verdict': verdict,
    'confidence': confidence,
    'reasoning': 'because',
    'missing': <String>[],
    'red_flags': <String>[],
  };
}

class _ThrowingLlm extends _FakeLlm {
  _ThrowingLlm() : super('pass', 1);
  @override
  Future<Map<String, dynamic>> structured({
    required String system,
    required String user,
    required Map<String, dynamic> schema,
    List<ImagePart> images = const [],
    double temperature = 0.2,
  }) async => throw LlmException('boom');
}

Task _task({List<Attempt> attempts = const []}) => Task(
  id: 't1',
  title: 'Write the quarterly report',
  definition: 'Report covers revenue and churn',
  createdAt: DateTime(2026, 1, 1),
  attempts: attempts,
);

const _good =
    'I finished the quarterly report covering revenue and churn, exported it to PDF '
    'and emailed it to the finance team; the sent email shows the attachment.';

Evidence _t(String v) => Evidence(EvidenceType.text, v);

void main() {
  group('hard rules', () {
    test('short evidence fails without calling the LLM', () async {
      final s = VerificationService(llm: _ThrowingLlm());
      final o = await s.submit(_task(), _t('did it'));
      expect(o.verdict, Verdict.fail);
      expect(o.flags, contains('too_short'));
    });

    test('duplicate evidence is rejected', () async {
      final s = VerificationService();
      final first = await s.submit(_task(), _t(_good));
      final again = await s.submit(
        _task(
          attempts: [
            Attempt(
              id: 'a',
              evidence: _good,
              hash: first.hash,
              verdict: Verdict.weak,
              confidence: .5,
              reasoning: '',
              message: '',
              createdAt: DateTime(2026, 1, 2),
            ),
          ],
        ),
        _t(_good),
      );
      expect(again.verdict, Verdict.fail);
      expect(again.flags, contains('duplicate'));
    });

    test('repetition is flagged', () async {
      final s = VerificationService();
      final o = await s.submit(
        _task(),
        _t(List.filled(30, 'report').join(' ')),
      );
      expect(o.flags, contains('repetition'));
    });
  });

  group('judging', () {
    test('offline judge passes detailed on-topic text', () async {
      final o = await VerificationService().submit(_task(), _t(_good));
      expect(o.verdict, Verdict.pass);
      expect(o.usedLlm, isFalse);
    });

    test('LLM pass below threshold is downgraded to weak', () async {
      final s = VerificationService(llm: _FakeLlm('pass', 0.65), strictness: 1);
      final o = await s.submit(_task(), _t(_good));
      expect(o.verdict, Verdict.weak);
    });

    test('LLM pass above threshold stays pass', () async {
      final s = VerificationService(llm: _FakeLlm('pass', 0.9));
      final o = await s.submit(_task(), _t(_good));
      expect(o.verdict, Verdict.pass);
      expect(o.usedLlm, isTrue);
    });

    test('LLM failure falls back to offline judge', () async {
      final s = VerificationService(llm: _ThrowingLlm());
      final o = await s.submit(_task(), _t(_good));
      expect(o.usedLlm, isFalse);
      expect(o.reasoning, contains('AI unavailable'));
    });
  });

  group('challenges', () {
    final now = DateTime(2026, 1, 1, 12);
    test('escalation ladder', () {
      expect(generateChallenge(1, now).type, ChallengeType.typing);
      expect(generateChallenge(2, now).type, ChallengeType.quiz);
      expect(generateChallenge(3, now).type, ChallengeType.timer);
      expect(generateChallenge(4, now).type, ChallengeType.explain);
      final micro = generateChallenge(5, now, seed: 2);
      expect(micro.type, ChallengeType.micro);
      expect(micro.detail, isNotEmpty);
      final c = generateChallenge(6, now);
      expect(c.type, ChallengeType.cooldown);
      expect(c.dueAt, now.add(const Duration(minutes: 2)));
      expect(generateChallenge(50, now).seconds, 15 * 60);
    });

    test('pledge grader ignores case and spacing only', () {
      expect(pledgeMatches('  ${pledgeText.toUpperCase()}  '), isTrue);
      expect(pledgeMatches('I will provide real proof'), isFalse);
    });
  });

  group('streak', () {
    Task done(DateTime d) =>
        _task().copyWith(status: TaskStatus.done, completedAt: d);
    final now = DateTime(2026, 3, 10, 9);
    test('counts consecutive days', () {
      final tasks = [
        done(DateTime(2026, 3, 10, 8)),
        done(DateTime(2026, 3, 9, 8)),
        done(DateTime(2026, 3, 7, 8)),
      ];
      expect(computeStreak(tasks, now), 2);
    });
    test('zero when nothing recent', () {
      expect(computeStreak([done(DateTime(2026, 3, 1))], now), 0);
    });
  });

  group('url guard', () {
    bool ok(String u) => isSafePublicUrl(Uri.parse(u));
    test(
      'allows public https',
      () => expect(ok('https://example.com/a'), isTrue),
    );
    test('blocks private and local targets', () {
      for (final u in [
        'http://localhost:3000',
        'http://127.0.0.1',
        'http://10.0.0.5',
        'http://192.168.1.1',
        'http://172.20.0.1',
        'http://169.254.169.254/latest',
        'http://[::1]/',
        'file:///etc/passwd',
        'ftp://example.com',
        'http://printer.local',
      ]) {
        expect(ok(u), isFalse, reason: u);
      }
    });
    test(
      'allows 172.32 (outside private range)',
      () => expect(ok('http://172.32.0.1'), isTrue),
    );
  });

  group('parsers', () {
    test('commit url', () {
      final r = parseCommitUrl(
        'https://github.com/flutter/flutter/commit/abc123',
      );
      expect(r?.owner, 'flutter');
      expect(r?.kind, CommitKind.commit);
      expect(r?.id, 'abc123');
    });
    test('pull url', () {
      expect(
        parseCommitUrl('https://github.com/a/b/pull/42')?.kind,
        CommitKind.pull,
      );
    });
    test('rejects non-github', () {
      expect(parseCommitUrl('https://gitlab.com/a/b/commit/1'), isNull);
    });
    test('extractPage strips scripts and reads meta', () {
      final p = extractPage(
        '<html><head><title>Hi</title><meta name="description" content="Desc">'
        '<script>evil()</script></head><body><p>Hello   world</p></body></html>',
      );
      expect(p.title, 'Hi');
      expect(p.description, 'Desc');
      expect(p.text, 'Hello world');
    });
  });

  test('task json round trip', () {
    final t = _task().copyWith(
      challenge: generateChallenge(6, DateTime(2026, 1, 1)),
    );
    final back = Task.fromJson(t.toJson());
    expect(back.title, t.title);
    expect(back.challenge?.type, ChallengeType.cooldown);
  });
}
