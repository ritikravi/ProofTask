import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../shared/fx.dart';
import '../../shared/receipt_card.dart';
import '../../shared/widgets.dart';

class VerdictScreen extends ConsumerStatefulWidget {
  const VerdictScreen({super.key, required this.taskId, required this.outcome});
  final String taskId;
  final Outcome? outcome;

  @override
  ConsumerState<VerdictScreen> createState() => _VerdictScreenState();
}

class _VerdictScreenState extends ConsumerState<VerdictScreen> {
  Outcome? _o;
  bool _disputed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _o = widget.outcome;
    final o = _o;
    if (o != null) _haptic(o);
  }

  void _haptic(Outcome o) {
    if (o.passed) {
      HapticFeedback.mediumImpact();
    } else if (o.verdict == Verdict.fail) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _dispute(Task task) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _DisputeDialog(),
    );
    if (note == null || note.length < 15) {
      if (note != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Say a bit more. 15+ characters.')),
        );
      }
      return;
    }
    setState(() => _busy = true);
    final o = await ref
        .read(verificationServiceProvider)
        .dispute(task, task.attempts.last.evidence, note);
    if (!mounted) return;
    ref.read(tasksProvider.notifier).applyDispute(task.id, o);
    setState(() {
      _o = o;
      _disputed = true;
      _busy = false;
    });
    _haptic(o);
  }

  @override
  Widget build(BuildContext context) {
    final o = _o;
    if (o == null) {
      // Deep-link / refresh: no outcome in memory.
      return Scaffold(
        body: Center(
          child: PrimaryButton(
            label: 'Back to task',
            onPressed: () => context.go('/task/${widget.taskId}'),
          ),
        ),
      );
    }
    final task = ref
        .watch(tasksProvider)
        .where((t) => t.id == widget.taskId)
        .firstOrNull;
    final reduce = reduceMotionOf(context, ref);
    final pass = o.passed;
    final bg = pass
        ? AppColors.lime
        : (o.verdict == Verdict.weak ? AppColors.amber : AppColors.coral);
    final fg = o.verdict == Verdict.fail ? Colors.white : AppColors.ink;
    final headline = switch (o.verdict) {
      Verdict.pass => 'Fine. That counts.',
      Verdict.weak => 'Technically evidence. Technically.',
      Verdict.fail => 'Nope.',
      Verdict.inconclusive => 'Inconclusive.',
    };
    final canDispute =
        !pass &&
        !_disputed &&
        o.usedLlm &&
        task != null &&
        task.attempts.isNotEmpty &&
        task.attempts.last.type == EvidenceType.text;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          if (!pass)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ZigZagRibbon(color: Colors.white24, height: 22),
              ),
            ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ShakeOnce(
                    enabled: !reduce && o.verdict == Verdict.fail,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Mascot(size: 72, skeptical: !pass),
                            const SizedBox(width: 12),
                            if (pass)
                              const Sparkle(size: 44, color: AppColors.ink),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          headline,
                          style: TextStyle(
                            color: fg,
                            fontSize: 32,
                            height: 38 / 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        VerdictBadge(o.verdict, confidence: o.confidence),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RoastBubble(o.message, praise: true),
                                const SizedBox(height: 12),
                                Text(
                                  o.reasoning,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                if (o.missing.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Missing: ${o.missing.join('; ')}',
                                    style: TextStyle(
                                      color: fg,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  (o.usedLlm
                                          ? 'Judged by AI'
                                          : 'Judged by offline rules') +
                                      (_disputed ? ' · appeal used' : ''),
                                  style: TextStyle(
                                    color: fg.withValues(alpha: 0.8),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_busy)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: CircularProgressIndicator(color: fg),
                            ),
                          ),
                        Row(
                          children: [
                            if (canDispute && !_busy)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _GhostButton(
                                    label: 'Dispute',
                                    icon: Icons.gavel_rounded,
                                    color: fg,
                                    onTap: () => _dispute(task),
                                  ),
                                ),
                              ),
                            if (task != null)
                              Expanded(
                                child: _GhostButton(
                                  label: 'Share receipt',
                                  icon: Icons.ios_share_rounded,
                                  color: fg,
                                  onTap: () => showReceiptDialog(
                                    context,
                                    taskTitle: task.title,
                                    verdict: o.verdict,
                                    confidence: o.confidence,
                                    message: o.message,
                                    when: DateTime.now(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: pass
                              ? 'Back to tasks'
                              : (task?.isLocked ?? true)
                              ? 'Face your challenge'
                              : 'Back to task',
                          color: pass ? AppColors.ink : Colors.white,
                          foreground: pass ? Colors.white : AppColors.ink,
                          onPressed: _busy
                              ? null
                              : () {
                                  if (pass) {
                                    context.go('/');
                                  } else if (task?.isLocked ?? true) {
                                    context.pushReplacement(
                                      '/task/${widget.taskId}/challenge',
                                    );
                                  } else {
                                    context.go('/task/${widget.taskId}');
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (pass && !reduce) const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.5),
      shape: const StadiumBorder(),
      minimumSize: const Size.fromHeight(48),
    ),
  );
}

class _DisputeDialog extends StatefulWidget {
  const _DisputeDialog();

  @override
  State<_DisputeDialog> createState() => _DisputeDialogState();
}

class _DisputeDialogState extends State<_DisputeDialog> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.surfaceDarkest,
    title: const Text('Dispute the verdict'),
    content: TextField(
      controller: _c,
      minLines: 3,
      maxLines: 6,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'What did the judge miss? You get one appeal.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _c.text.trim()),
        child: const Text('Appeal', style: TextStyle(color: AppColors.lime)),
      ),
    ],
  );
}
