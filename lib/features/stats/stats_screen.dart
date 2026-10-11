import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../shared/widgets.dart';
import '../tasks/task_list_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final attempts = tasks.expand((t) => t.attempts).toList();
    final judged = attempts
        .where((a) => a.verdict != Verdict.inconclusive)
        .toList();
    final passed = judged.where((a) => a.verdict == Verdict.pass).length;
    final rate = judged.isEmpty ? 0 : (passed / judged.length * 100).round();
    final excuse = judged.isEmpty ? 0 : 100 - rate;
    final streak = computeStreak(tasks, DateTime.now());

    final today = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: i)),
    ];
    int onDay(DateTime d) => tasks
        .where(
          (t) =>
              t.completedAt != null &&
              t.completedAt!.year == d.year &&
              t.completedAt!.month == d.month &&
              t.completedAt!.day == d.day,
        )
        .length;
    final counts = [for (final d in days) onDay(d)];
    final maxCount = counts.fold<int>(1, (m, c) => c > m ? c : m);

    final roasted =
        tasks
            .map(
              (t) => (
                t,
                t.attempts.where((a) => a.verdict != Verdict.pass).length,
              ),
            )
            .where((e) => e.$2 > 0)
            .toList()
          ..sort((a, b) => b.$2.compareTo(a.$2));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Streak',
                      value: '$streak d',
                      lime: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(label: 'Pass rate', value: '$rate%'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(label: 'Excuse index', value: '$excuse%'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      label: 'Tasks proven',
                      value: '${tasks.where((t) => t.isDone).length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last 7 days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${counts[i]}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 6 + 70 * counts[i] / maxCount,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: counts[i] == 0
                                          ? AppColors.surfaceDeep
                                          : AppColors.lime,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'MTWTFSS'[days[i].weekday - 1],
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Most roasted',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (roasted.isEmpty)
                      const Text(
                        'Nobody roasted yet. Give it time.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    for (final (t, n) in roasted.take(5))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$n×',
                              style: const TextStyle(
                                color: AppColors.coral,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.lime = false});
  final String label;
  final String value;
  final bool lime;

  @override
  Widget build(BuildContext context) {
    final fg = lime ? AppColors.ink : Colors.white;
    return BentoCard(
      color: lime ? AppColors.lime : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontSize: 32,
              height: 38 / 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: lime ? AppColors.ink : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
