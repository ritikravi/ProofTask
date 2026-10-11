import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models.dart';
import '../../core/storage.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(tasksProvider).where((t) => t.id == taskId).firstOrNull;
    
    if (task == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Task not found'),
        ),
      );
    }

    final priorityColor = task.priority == TaskPriority.high
        ? AppColors.coral
        : task.priority == TaskPriority.medium
            ? AppColors.amber
            : AppColors.success;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.ink),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog(context, ref, task);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, color: AppColors.coral),
                    SizedBox(width: 12),
                    Text('Delete Task'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Task header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.description_rounded,
                    color: AppColors.surface,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.definition.isEmpty
                            ? 'No description'
                            : task.definition,
                        style: TextStyle(
                          color: AppColors.ink.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority.name.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Acceptance Criteria
          if (task.acceptanceCriteria.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.surface, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Acceptance Criteria',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...task.acceptanceCriteria.split('\n').map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              color: AppColors.ink.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Required Evidence
          if (task.requiredEvidenceTypes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Required Evidence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: task.requiredEvidenceTypes.map((type) {
                      final isUrl = type.toLowerCase() == 'url';
                      final isScreenshot = type.toLowerCase() == 'screenshot';
                      final isText = type.toLowerCase() == 'text';
                      final isCommit = type.toLowerCase() == 'commit';
                      
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isUrl || isScreenshot
                                ? AppColors.surface.withOpacity(0.15)
                                : AppColors.outline.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUrl || isScreenshot
                                  ? AppColors.surface
                                  : AppColors.outline,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isUrl
                                    ? Icons.link_rounded
                                    : isScreenshot
                                        ? Icons.image_rounded
                                        : isText
                                            ? Icons.notes_rounded
                                            : Icons.commit_rounded,
                                color: isUrl || isScreenshot
                                    ? AppColors.surface
                                    : AppColors.ink.withOpacity(0.5),
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                type,
                                style: TextStyle(
                                  color: isUrl || isScreenshot
                                      ? AppColors.surface
                                      : AppColors.ink.withOpacity(0.5),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Due Date
          if (task.deadline != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: _isOverdue(task.deadline!)
                        ? AppColors.coral
                        : AppColors.ink.withOpacity(0.6),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDeadline(task.deadline!),
                    style: TextStyle(
                      color: _isOverdue(task.deadline!)
                          ? AppColors.coral
                          : AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Status
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: AppColors.ink.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(task.status),
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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
          
          const SizedBox(height: 32),
          
          // CTA Button
          if (!task.isDone)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: task.isLocked
                    ? () => context.push('/task/${task.id}/challenge')
                    : () => context.push('/task/${task.id}/submit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.isLocked ? AppColors.coral : AppColors.surface,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.isLocked
                          ? 'Complete Challenge First'
                          : 'Show me the receipts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      task.isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
      case TaskStatus.verified:
        return AppColors.success;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.pendingVerification:
        return AppColors.statusPending;
      case TaskStatus.needsRevision:
        return AppColors.coral;
      case TaskStatus.blocked:
        return AppColors.coral;
      default:
        return AppColors.ink.withOpacity(0.5);
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.pendingVerification:
        return 'Pending';
      case TaskStatus.needsRevision:
        return 'Needs Revision';
      case TaskStatus.verified:
        return 'Verified';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.done:
        return 'Done';
    }
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
    if (diff == 0) return 'Today, Dec ${deadline.day}';
    if (diff == 1) return 'Tomorrow, Dec ${deadline.day}';
    return 'Dec ${deadline.day}';
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Task task) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(tasksProvider.notifier).remove(task.id);
              Navigator.pop(c);
              context.go('/');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.coral),
            ),
          ),
        ],
      ),
    );
  }
}
