import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../shared/widgets.dart';
import 'challenge_content.dart';

// ------------------------------------------------------------ break down

class BreakdownCard extends ConsumerStatefulWidget {
  const BreakdownCard({super.key, required this.task});
  final Task task;

  @override
  ConsumerState<BreakdownCard> createState() => _BreakdownCardState();
}

class _BreakdownCardState extends ConsumerState<BreakdownCard> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    final subs = await suggestSubtasks(widget.task, ref.read(llmProvider));
    if (!mounted) return;
    ref.read(tasksProvider.notifier).addSubtasks(widget.task.id, subs);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split into ${subs.length} smaller tasks.')),
    );
    context.go('/');
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: BentoCard(
      color: AppColors.surfaceDarkest,
      radius: AppRadius.cardSm,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined, color: AppColors.lime),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Stuck? Skip the punishment: break this task into smaller ones.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lime,
                  ),
                )
              : TextButton(
                  onPressed: _go,
                  child: const Text(
                    'Break it down',
                    style: TextStyle(color: AppColors.lime),
                  ),
                ),
        ],
      ),
    ),
  );
}

// ------------------------------------------------------------------ quiz

class QuizChallenge extends ConsumerStatefulWidget {
  const QuizChallenge({super.key, required this.task, required this.onDone});
  final Task task;
  final VoidCallback onDone;

  @override
  ConsumerState<QuizChallenge> createState() => _QuizChallengeState();
}

class _QuizChallengeState extends ConsumerState<QuizChallenge> {
  late Future<List<QuizQuestion>> _quiz = _load();
  final Map<int, int> _picked = {};
  bool _graded = false;

  Future<List<QuizQuestion>> _load() =>
      buildQuiz(widget.task, ref.read(llmProvider));

  void _retry() => setState(() {
    _picked.clear();
    _graded = false;
    _quiz = _load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizQuestion>>(
      future: _quiz,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.lime),
          );
        }
        final qs = snap.data!;
        final correct = [
          for (var i = 0; i < qs.length; i++)
            if (_picked[i] == qs[i].answer) i,
        ].length;
        final passed = correct >= quizPassMark;
        return ListView(
          children: [
            for (var i = 0; i < qs.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${i + 1}/${qs.length}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        qs[i].question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var j = 0; j < qs[i].options.length; j++)
                        _Option(
                          label: qs[i].options[j],
                          selected: _picked[i] == j,
                          state: !_graded
                              ? null
                              : j == qs[i].answer
                              ? true
                              : (_picked[i] == j ? false : null),
                          onTap: _graded
                              ? null
                              : () => setState(() => _picked[i] = j),
                        ),
                    ],
                  ),
                ),
              ),
            if (_graded && !passed)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Not enough right. Reading is also a skill.',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            PrimaryButton(
              label: !_graded
                  ? 'Check answers'
                  : passed
                  ? 'Passed ($correct/${qs.length}). Continue'
                  : 'Try a fresh quiz',
              onPressed: !_graded
                  ? (_picked.length == qs.length
                        ? () => setState(() => _graded = true)
                        : null)
                  : (passed ? widget.onDone : _retry),
            ),
          ],
        );
      },
    );
  }
}

/// [state]: true = correct answer, false = your wrong pick, null = neutral.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool? state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = state == true
        ? AppColors.lime
        : state == false
        ? AppColors.coral
        : (selected ? Colors.white : AppColors.outline);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected ? AppColors.surfaceDeep : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          side: BorderSide(color: border, width: selected ? 2 : 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (state == true)
                  const Icon(Icons.check_rounded, color: AppColors.lime),
                if (state == false)
                  const Icon(Icons.close_rounded, color: AppColors.coral),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- explain

class ExplainChallenge extends ConsumerStatefulWidget {
  const ExplainChallenge({super.key, required this.task, required this.onDone});
  final Task task;
  final VoidCallback onDone;

  @override
  ConsumerState<ExplainChallenge> createState() => _ExplainChallengeState();
}

class _ExplainChallengeState extends ConsumerState<ExplainChallenge> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _feedback;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final last = widget.task.attempts.isEmpty
        ? null
        : widget.task.attempts.last;
    final r = await checkExplanation(
      widget.task,
      last,
      _c.text,
      ref.read(llmProvider),
    );
    if (!mounted) return;
    if (r.ok) {
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _feedback = r.feedback;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.task.attempts.isEmpty
        ? null
        : widget.task.attempts.last;
    return ListView(
      children: [
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explain it',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (last != null)
                Text(
                  'The judge said: ${last.reasoning}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'What was missing from your proof? Two sentences.',
                  errorText: _feedback,
                  errorMaxLines: 3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _busy ? 'Reading your explanation…' : 'Submit explanation',
          onPressed: (_busy || _c.text.trim().length < 20) ? null : _check,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- micro

class MicroChallenge extends StatefulWidget {
  const MicroChallenge({
    super.key,
    required this.challenge,
    required this.onDone,
  });
  final Challenge challenge;
  final VoidCallback onDone;

  @override
  State<MicroChallenge> createState() => _MicroChallengeState();
}

class _MicroChallengeState extends State<MicroChallenge> {
  late int _wait = widget.challenge.seconds;
  Timer? _t;
  double _slide = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_wait <= 1) _t?.cancel();
      if (mounted) setState(() => _wait = (_wait - 1).clamp(0, 1 << 30));
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = _wait == 0;
    return ListView(
      children: [
        BentoCard(
          child: Column(
            children: [
              const Icon(
                Icons.self_improvement_rounded,
                size: 40,
                color: AppColors.lime,
              ),
              const SizedBox(height: 8),
              Text(
                widget.challenge.detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.challenge.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BentoCard(
          color: AppColors.surfaceDeep,
          child: Column(
            children: [
              Text(
                unlocked
                    ? 'Slide all the way to confirm'
                    : 'Unlocks in ${mmss(_wait)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Slider(
                value: _slide,
                onChanged: unlocked ? (v) => setState(() => _slide = v) : null,
                onChangeEnd: (v) {
                  if (v >= 0.98) {
                    widget.onDone();
                  } else {
                    setState(() => _slide = 0);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
