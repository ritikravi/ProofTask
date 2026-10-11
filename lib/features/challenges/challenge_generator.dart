import '../../core/models.dart';

const pledgeText =
    'I will provide real proof of real work and stop pretending that a vague sentence counts as evidence.';

const microTasks = [
  'Do 10 squats.',
  'Drink a full glass of water.',
  'Stand up and stretch for 30 seconds.',
  'Take 10 slow, deep breaths.',
  'Walk to another room and back.',
];

/// Escalation ladder (PLAN.md §4.3). [failedAttempts] counts non-pass,
/// non-inconclusive attempts, including the one that just happened.
Challenge generateChallenge(int failedAttempts, DateTime now, {int seed = 0}) {
  switch (failedAttempts) {
    case <= 1:
      return const Challenge(
        type: ChallengeType.typing,
        prompt: pledgeText,
        seconds: 0,
      );
    case 2:
      return const Challenge(
        type: ChallengeType.quiz,
        prompt: 'Three quick questions about your own task.',
        seconds: 0,
      );
    case 3:
      return const Challenge(
        type: ChallengeType.timer,
        prompt:
            'Hold still for 45 seconds. Leave the app and the clock restarts.',
        seconds: 45,
      );
    case 4:
      return const Challenge(
        type: ChallengeType.explain,
        prompt: 'In two sentences, say what was missing from your proof.',
        seconds: 0,
      );
    case 5:
      return Challenge(
        type: ChallengeType.micro,
        prompt:
            'Do it for real, then confirm. The slider unlocks after a pause.',
        seconds: 15,
        detail: microTasks[seed.abs() % microTasks.length],
      );
    default:
      final minutes = ((failedAttempts - 5) * 2).clamp(2, 15);
      return Challenge(
        type: ChallengeType.cooldown,
        prompt: 'Cooldown. Think about what real proof looks like.',
        seconds: minutes * 60,
        dueAt: now.add(Duration(minutes: minutes)),
      );
  }
}

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Typing challenge grader: exact match modulo case and whitespace.
bool pledgeMatches(String typed) => _norm(typed) == _norm(pledgeText);

/// Failures at which "break the task down" is offered.
const breakdownThreshold = 3;

int failedCount(Task t) => t.attempts
    .where(
      (a) => a.verdict != Verdict.pass && a.verdict != Verdict.inconclusive,
    )
    .length;
