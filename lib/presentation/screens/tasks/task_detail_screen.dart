import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/models/task.dart';
import '../../providers/task_provider.dart';
import 'add_task_screen.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(taskCategoriesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildTaskDetails(categoriesAsync),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _currentTask.priority.color,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _currentTask.priority.color,
                _currentTask.priority.color.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildPriorityBadge(),
                  const SizedBox(height: 12),
                  _buildTaskTitle(),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _editTask,
          icon: const Icon(Iconsax.edit),
          tooltip: 'Edit Task',
        ),
        _buildPopupMenu(),
      ],
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _currentTask.priority.icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '${_currentTask.priority.displayName} Priority',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTitle() {
    return Text(
      _currentTask.title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            decoration: _currentTask.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'toggle_status',
          child: Row(
            children: [
              Icon(
                _currentTask.status == TaskStatus.completed
                    ? Iconsax.close_circle
                    : Iconsax.tick_circle,
              ),
              const SizedBox(width: 8),
              Text(_currentTask.status == TaskStatus.completed
                  ? 'Mark as Pending'
                  : 'Mark as Completed'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Iconsax.trash, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Task', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(AsyncValue<List<TaskCategory>> categoriesAsync) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 20),
            if (_hasDescription()) ...[
              _buildDescriptionSection(),
              const SizedBox(height: 20),
            ],
            _buildCategorySection(categoriesAsync),
            if (_hasDueDate()) ...[
              _buildDueDateSection(),
              const SizedBox(height: 20),
            ],
            if (_hasReminder()) ...[
              _buildReminderSection(),
              const SizedBox(height: 20),
            ],
            if (_hasTags()) ...[
              _buildTagsSection(),
              const SizedBox(height: 20),
            ],
            _buildMetadataSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _hasDescription() => _currentTask.description != null && _currentTask.description!.isNotEmpty;
  bool _hasDueDate() => _currentTask.dueDate != null;
  bool _hasReminder() => _currentTask.reminderDate != null;
  bool _hasTags() => _currentTask.tags.isNotEmpty;

  Widget _buildDescriptionSection() {
    return _buildSectionCard(
      'Description',
      Iconsax.document_text,
      child: Text(
        _currentTask.description!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }

  Widget _buildCategorySection(AsyncValue<List<TaskCategory>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) => _buildCategoryWidget(categories),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryWidget(List<TaskCategory> categories) {
    if (_currentTask.categoryId == null) return const SizedBox.shrink();
    
    final category = categories.firstWhere(
      (c) => c.id == _currentTask.categoryId,
      orElse: () => categories.first,
    );
    
    return Column(
      children: [
        _buildSectionCard(
          'Category',
          Iconsax.category,
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 20),
              const SizedBox(width: 12),
              Text(
                category.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDueDateSection() {
    return _buildSectionCard(
      'Due Date',
      Iconsax.calendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, y').format(_currentTask.dueDate!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormat('h:mm a').format(_currentTask.dueDate!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          _buildDueDateBadge(),
        ],
      ),
    );
  }

  Widget _buildDueDateBadge() {
    if (_currentTask.isOverdue) {
      return _buildStatusBadge('Overdue', Colors.red, Iconsax.danger);
    } else if (_currentTask.isDueToday) {
      return _buildStatusBadge('Due Today', Colors.orange, Iconsax.clock);
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    return _buildSectionCard(
      'Reminder',
      Iconsax.notification,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, y').format(_currentTask.reminderDate!),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Text(
            DateFormat('h:mm a').format(_currentTask.reminderDate!),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return _buildSectionCard(
      'Tags',
      Iconsax.tag,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _currentTask.tags.map(_buildTagChip).toList(),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: ModernTheme.primaryOrange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return _buildSectionCard(
      'Task Information',
      Iconsax.info_circle,
      child: Column(
        children: [
          _buildInfoRow('Created', DateFormat('MMM d, y • h:mm a').format(_currentTask.createdAt)),
          const SizedBox(height: 8),
          _buildInfoRow('Last Updated', DateFormat('MMM d, y • h:mm a').format(_currentTask.updatedAt)),
          if (_currentTask.completedAt != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Completed', DateFormat('MMM d, y • h:mm a').format(_currentTask.completedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildToggleStatusButton()),
          const SizedBox(width: 12),
          _buildEditButton(),
        ],
      ),
    );
  }

  Widget _buildToggleStatusButton() {
    return ElevatedButton.icon(
      onPressed: _toggleTaskStatus,
      icon: Icon(
        _currentTask.status == TaskStatus.completed
            ? Iconsax.close_circle
            : Iconsax.tick_circle,
      ),
      label: Text(
        _currentTask.status == TaskStatus.completed
            ? 'Mark as Pending'
            : 'Mark as Completed',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _currentTask.status == TaskStatus.completed
            ? Colors.orange
            : Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: _editTask,
      style: ElevatedButton.styleFrom(
        backgroundColor: ModernTheme.primaryOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
      ),
      child: const Icon(Iconsax.edit),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _currentTask.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _currentTask.status.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _currentTask.status.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _currentTask.status == TaskStatus.completed
                  ? Iconsax.tick_circle
                  : _currentTask.status == TaskStatus.inProgress
                      ? Iconsax.clock
                      : Iconsax.timer_1,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  _currentTask.status.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _currentTask.status.color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'toggle_status':
        _toggleTaskStatus();
        break;
      case 'delete':
        _deleteTask();
        break;
    }
  }

  Future<void> _toggleTaskStatus() async {
    try {
      await ref.read(taskProvider.notifier).toggleTaskStatus(_currentTask.id);
      
      setState(() {
        _currentTask = _currentTask.copyWith(
          status: _currentTask.status == TaskStatus.completed
              ? TaskStatus.pending
              : TaskStatus.completed,
          completedAt: _currentTask.status == TaskStatus.completed
              ? null
              : DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _currentTask.status == TaskStatus.completed
                  ? 'Task marked as completed!'
                  : 'Task marked as pending!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(task: _currentTask),
      ),
    );

    if (result == true && mounted) {
      ref.read(taskProvider.notifier).loadTasks();
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await _showDeleteConfirmation();

    if (confirmed == true) {
      try {
        await ref.read(taskProvider.notifier).deleteTask(_currentTask.id);
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${_currentTask.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}