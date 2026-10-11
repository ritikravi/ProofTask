import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';
import '../../shared/fx.dart';
import '../../shared/widgets.dart';

enum _Filter { all, todo, inProgress, done }

int computeStreak(List<Task> tasks, DateTime now) {
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  final days = {
    for (final t in tasks)
      if (t.completedAt != null) day(t.completedAt!),
  };
  var cursor = day(now);
  if (!days.contains(cursor)) cursor = cursor.subtract(const Duration(days: 1));
  var n = 0;
  while (days.contains(cursor)) {
    n++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return n;
}

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final shown = tasks.where((t) {
      return switch (_filter) {
        _Filter.all => true,
        _Filter.todo => t.status == TaskStatus.todo,
        _Filter.inProgress => t.status == TaskStatus.inProgress,
        _Filter.done => t.isDone,
      };
    }).toList();

    final totalTasks = tasks.length;
    final completed = tasks.where((t) => t.isDone).length;
    final successRate = totalTasks > 0 ? (completed / totalTasks * 100).round() : 0;
    final todoCount = tasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressCount = tasks.where((t) => t.status == TaskStatus.inProgress).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning, Ritik! 👋',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Show me the receipts.',
                              style: TextStyle(
                                color: AppColors.ink.withOpacity(0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Mascot(size: 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$totalTasks',
                          label: 'Tasks',
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '$completed',
                          label: 'Completed',
                          color: AppColors.success.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          value: '$successRate%',
                          label: 'Success Rate',
                          color: AppColors.lime.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All ($totalTasks)',
                          selected: _filter == _Filter.all,
                          onTap: () => setState(() => _filter = _Filter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Todo ($todoCount)',
                          selected: _filter == _Filter.todo,
                          onTap: () => setState(() => _filter = _Filter.todo),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'In Progress ($inProgressCount)',
                          selected: _filter == _Filter.inProgress,
                          onTap: () => setState(() => _filter = _Filter.inProgress),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Done ($completed)',
                          selected: _filter == _Filter.done,
                          onTap: () => setState(() => _filter = _Filter.done),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Task list
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Mascot(size: 80, paper: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks yet.\nTap + to create one!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.ink.withOpacity(0.6),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: shown.length,
                      itemBuilder: (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TaskCard(task: shown[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTaskSheet(context),
        backgroundColor: AppColors.surface,
        child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(),
    );
  }

  Future<void> _showNewTaskSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NewTaskSheet(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppColors.ink.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.surface : AppColors.outline,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final priorityColor = task.priority == TaskPriority.high
        ? AppColors.coral
        : task.priority == TaskPriority.medium
            ? AppColors.amber
            : AppColors.success;

    return GestureDetector(
      onTap: () => context.push('/task/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.isDone
                    ? AppColors.success
                    : task.status == TaskStatus.inProgress
                        ? AppColors.statusInProgress
                        : AppColors.outline,
                shape: BoxShape.circle,
              ),
              child: Icon(
                task.isDone
                    ? Icons.check_rounded
                    : task.isLocked
                        ? Icons.lock_rounded
                        : Icons.circle_outlined,
                color: task.isDone || task.status == TaskStatus.inProgress
                    ? Colors.white
                    : AppColors.ink.withOpacity(0.3),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.definition.isEmpty
                        ? 'No description'
                        : task.definition,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink.withOpacity(0.5),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (task.deadline != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDeadline(task.deadline!),
                    style: TextStyle(
                      color: _isOverdue(task.deadline!)
                          ? AppColors.coral
                          : AppColors.ink.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  bool _isOverdue(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final diff = deadlineDay.difference(today).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'Dec ${deadline.day}';
  }
}

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.task_alt_rounded,
            label: 'Tasks',
            selected: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: 'Stats',
            onTap: () => context.push('/stats'),
          ),
          const SizedBox(width: 60), // Space for FAB
          _NavItem(
            icon: Icons.shield_rounded,
            label: 'Challenges',
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.surface : AppColors.ink.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.surface : AppColors.ink.withOpacity(0.4),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTaskSheet extends ConsumerStatefulWidget {
  const _NewTaskSheet();

  @override
  ConsumerState<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends ConsumerState<_NewTaskSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _def = TextEditingController();
  DateTime? _deadline;
  TaskPriority _priority = TaskPriority.medium;

  @override
  void dispose() {
    _title.dispose();
    _def.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Task',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.next,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Task title',
                labelStyle: TextStyle(color: AppColors.muted),
              ),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Too short' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _def,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: TextStyle(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  ref.read(tasksProvider.notifier).add(
                        _title.text,
                        _def.text,
                        deadline: _deadline,
                        priority: _priority,
                      );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                ),
                child: const Text(
                  'Create Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
