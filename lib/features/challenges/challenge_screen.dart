import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../shared/widgets.dart';
import 'challenge_extra.dart';
import 'challenge_generator.dart';

class ChallengeScreen extends ConsumerWidget {
  const ChallengeScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref
        .watch(tasksProvider)
        .where((t) => t.id == taskId)
        .firstOrNull;
    final ch = task?.challenge;

    void done() {
      ref.read(tasksProvider.notifier).clearChallenge(taskId);
      context.go('/task/$taskId');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/task/$taskId'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ch == null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Nothing to face. Enjoy it.',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Back to task',
                        onPressed: () => context.go('/task/$taskId'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      if (failedCount(task!) >= breakdownThreshold)
                        BreakdownCard(task: task),
                      Expanded(child: _body(ch, task, done)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _body(Challenge ch, Task task, VoidCallback done) {
    return switch (ch.type) {
      ChallengeType.quiz => QuizChallenge(task: task, onDone: done),
      ChallengeType.explain => ExplainChallenge(task: task, onDone: done),
      ChallengeType.micro => MicroChallenge(challenge: ch, onDone: done),
      ChallengeType.typing => _TypingChallenge(onDone: done),
      ChallengeType.timer => _TimerChallenge(challenge: ch, onDone: done),
      ChallengeType.cooldown => _CooldownChallenge(challenge: ch, onDone: done),
    };
  }
}

class _TypingChallenge extends StatefulWidget {
  const _TypingChallenge({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_TypingChallenge> createState() => _TypingChallengeState();
}

class _TypingChallengeState extends State<_TypingChallenge> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = pledgeMatches(_c.text);
    return ListView(
      children: [
        BentoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type the pledge',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              BentoCard(
                color: AppColors.surfaceDeep,
                radius: AppRadius.tile,
                padding: const EdgeInsets.all(14),
                child: Text(
                  pledgeText,
                  style: const TextStyle(fontSize: 15, height: 22 / 15),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Type it exactly…'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: ok ? 'Pledge accepted. Continue' : 'Not an exact match yet',
          onPressed: ok ? widget.onDone : null,
        ),
      ],
    );
  }
}

class _TimerChallenge extends StatefulWidget {
  const _TimerChallenge({required this.challenge, required this.onDone});
  final Challenge challenge;
  final VoidCallback onDone;

  @override
  State<_TimerChallenge> createState() => _TimerChallengeState();
}

class _TimerChallengeState extends State<_TimerChallenge>
    with WidgetsBindingObserver {
  late int _left = widget.challenge.seconds;
  Timer? _t;
  bool _reset = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    _t?.cancel();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _t?.cancel();
      }
      if (mounted) setState(() => _left = (_left - 1).clamp(0, 1 << 30));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app breaks the hold.
    if (_left > 0 &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden)) {
      setState(() {
        _left = widget.challenge.seconds;
        _reset = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.challenge.seconds;
    return ListView(
      children: [
        BentoCard(
          child: Column(
            children: [
              const Text(
                'Focus hold',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.challenge.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Text(
                mmss(_left),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 1 : 1 - _left / total,
                  minHeight: 6,
                  color: AppColors.lime,
                  backgroundColor: Colors.white24,
                ),
              ),
              if (_reset)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'You left. The clock restarted.',
                    style: TextStyle(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _left == 0 ? 'Done. Continue' : 'Holding…',
          onPressed: _left == 0 ? widget.onDone : null,
        ),
      ],
    );
  }
}

class _CooldownChallenge extends StatefulWidget {
  const _CooldownChallenge({required this.challenge, required this.onDone});
  final Challenge challenge;
  final VoidCallback onDone;

  @override
  State<_CooldownChallenge> createState() => _CooldownChallengeState();
}

class _CooldownChallengeState extends State<_CooldownChallenge> {
  Timer? _t;

  int get _left {
    final due = widget.challenge.dueAt;
    if (due == null) return 0;
    final s = due.difference(DateTime.now()).inSeconds;
    return s < 0 ? 0 : s + 1;
  }

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _left;
    return ListView(
      children: [
        BentoCard(
          child: Column(
            children: [
              const Icon(
                Icons.lock_clock_rounded,
                size: 40,
                color: AppColors.lime,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cooldown',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.challenge.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              Text(
                mmss(left),
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: left == 0 ? 'Cooldown over. Continue' : 'Locked',
          icon: left == 0 ? null : Icons.lock_rounded,
          onPressed: left == 0 ? widget.onDone : null,
        ),
      ],
    );
  }
}
