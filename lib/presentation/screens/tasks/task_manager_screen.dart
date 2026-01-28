import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/models/task.dart';
import '../../providers/task_provider.dart';
import 'add_task_screen.dart';
import 'task_detail_screen.dart';

class TaskManagerScreen extends ConsumerStatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  ConsumerState<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends ConsumerState<TaskManagerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasks();
      ref.read(taskCategoriesProvider.notifier).loadCategories();
      ref.read(taskStatisticsProvider.notifier).loadStatistics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: _buildHeaderSlivers,
        body: _buildTabBarView(tasksAsync),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  List<Widget> _buildHeaderSlivers(BuildContext context, bool innerBoxIsScrolled) {
    return [
      SliverAppBar(
        floating: true,
        pinned: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        expandedHeight: 200,
        flexibleSpace: _buildFlexibleSpace(),
        bottom: _buildTabBar(),
      ),
    ];
  }

  Widget _buildFlexibleSpace() {
    final statsAsync = ref.watch(taskStatisticsProvider);
    
    return FlexibleSpaceBar(
      background: Container(
        decoration: _buildGradientDecoration(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(statsAsync),
                const SizedBox(height: 20),
                _buildSearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ModernTheme.primaryOrange.withValues(alpha: 0.15),
          ModernTheme.primaryOrange.withValues(alpha: 0.05),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      onTap: _updateFilterForTab,
      tabs: const [
        Tab(text: 'All'),
        Tab(text: 'Pending'),
        Tab(text: 'In Progress'),
        Tab(text: 'Completed'),
      ],
    );
  }

  Widget _buildTabBarView(AsyncValue<List<Task>> tasksAsync) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTaskList(tasksAsync, null),
        _buildTaskList(tasksAsync, TaskStatus.pending),
        _buildTaskList(tasksAsync, TaskStatus.inProgress),
        _buildTaskList(tasksAsync, TaskStatus.completed),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToAddTask,
      backgroundColor: ModernTheme.primaryOrange,
      foregroundColor: Colors.white,
      icon: const Icon(Iconsax.add),
      label: const Text('Add Task'),
    );
  }

  Widget _buildHeader(AsyncValue<Map<String, int>> statsAsync) {
    return Row(
      children: [
        _buildHeaderIcon(),
        const SizedBox(width: 16),
        Expanded(child: _buildHeaderText(statsAsync)),
        _buildFilterButton(),
      ],
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ModernTheme.orangeGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Iconsax.task_square, color: Colors.white, size: 28),
    );
  }

  Widget _buildHeaderText(AsyncValue<Map<String, int>> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Manager',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
        _buildStatsText(statsAsync),
      ],
    );
  }

  Widget _buildStatsText(AsyncValue<Map<String, int>> statsAsync) {
    return statsAsync.when(
      data: (stats) => Text(
        '${stats['total']} tasks • ${stats['pending']} pending',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      loading: () => Text(
        'Loading...',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      error: (_, _) => Text(
        'Error loading stats',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasActiveFilters = ref.watch(taskFilterProvider).hasActiveFilters;
    
    return IconButton(
      onPressed: _showFilterDialog,
      icon: Icon(
        hasActiveFilters ? Iconsax.filter_edit : Iconsax.filter,
        color: hasActiveFilters ? ModernTheme.primaryOrange : null,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: _buildSearchBarDecoration(),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearchQuery,
        decoration: _buildSearchInputDecoration(),
      ),
    );
  }

  BoxDecoration _buildSearchBarDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  InputDecoration _buildSearchInputDecoration() {
    return InputDecoration(
      hintText: 'Search tasks...',
      prefixIcon: const Icon(Iconsax.search_normal_1),
      suffixIcon: _searchController.text.isNotEmpty ? _buildClearButton() : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildClearButton() {
    return IconButton(
      icon: const Icon(Iconsax.close_circle),
      onPressed: _clearSearch,
    );
  }

  void _updateSearchQuery(String value) {
    ref.read(taskFilterProvider.notifier).state = 
        ref.read(taskFilterProvider).copyWith(searchQuery: value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(taskFilterProvider.notifier).state = 
        ref.read(taskFilterProvider).copyWith(searchQuery: '');
  }

  Widget _buildTaskList(AsyncValue<List<Task>> tasksAsync, TaskStatus? statusFilter) {
    return tasksAsync.when(
      data: (tasks) => _buildTaskListData(tasks, statusFilter),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildTaskListData(List<Task> tasks, TaskStatus? statusFilter) {
    final filteredTasks = _filterTasksByStatus(tasks, statusFilter);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState(statusFilter);
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) => _buildTaskCard(filteredTasks[index]),
      ),
    );
  }

  List<Task> _filterTasksByStatus(List<Task> tasks, TaskStatus? statusFilter) {
    return statusFilter != null 
        ? tasks.where((task) => task.status == statusFilter).toList()
        : tasks;
  }

  Widget _buildTaskCard(Task task) {
    return _TaskCard(
      task: task,
      onTap: () => _navigateToTaskDetail(task),
      onToggleStatus: () => _toggleTaskStatus(task.id),
      onDelete: () => _deleteTask(task),
    );
  }

  Future<void> _refreshTasks() async {
    await ref.read(taskProvider.notifier).loadTasks();
    await ref.read(taskStatisticsProvider.notifier).refresh();
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.danger,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load tasks',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(taskProvider.notifier).loadTasks(),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TaskStatus? statusFilter) {
    final (title, subtitle, icon) = _getEmptyStateContent(statusFilter);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmptyStateIcon(icon),
            const SizedBox(height: 24),
            _buildEmptyStateText(title, subtitle),
            if (statusFilter == null) _buildEmptyStateButton(),
          ],
        ),
      ),
    );
  }

  (String, String, IconData) _getEmptyStateContent(TaskStatus? statusFilter) {
    return switch (statusFilter) {
      TaskStatus.pending => (
        'No pending tasks',
        'All caught up! Add a new task to get started.',
        Iconsax.tick_circle
      ),
      TaskStatus.inProgress => (
        'No tasks in progress',
        'Start working on a pending task to see it here.',
        Iconsax.clock
      ),
      TaskStatus.completed => (
        'No completed tasks',
        'Complete some tasks to see your achievements here.',
        Iconsax.medal_star
      ),
      _ => (
        'No tasks yet',
        'Create your first task to get organized!',
        Iconsax.task_square
      ),
    };
  }

  Widget _buildEmptyStateIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEmptyStateText(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyStateButton() {
    return Column(
      children: [
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _navigateToAddTask,
          icon: const Icon(Iconsax.add),
          label: const Text('Add Your First Task'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ModernTheme.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _updateFilterForTab(int index) {
    final status = switch (index) {
      1 => TaskStatus.pending,
      2 => TaskStatus.inProgress,
      3 => TaskStatus.completed,
      _ => null,
    };
    
    ref.read(taskFilterProvider.notifier).state = 
        ref.read(taskFilterProvider).copyWith(status: status);
  }

  void _showFilterDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter dialog coming soon!')),
    );
  }

  Future<void> _navigateToAddTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    
    if (result == true) {
      _refreshTasksAndStats();
    }
  }

  Future<void> _navigateToTaskDetail(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
    );
    
    if (result == true) {
      _refreshTasksAndStats();
    }
  }

  void _refreshTasksAndStats() {
    ref.read(taskProvider.notifier).loadTasks();
    ref.read(taskStatisticsProvider.notifier).refresh();
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    try {
      await ref.read(taskProvider.notifier).toggleTaskStatus(taskId);
      ref.read(taskStatisticsProvider.notifier).refresh();
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

  Future<void> _deleteTask(Task task) async {
    final confirmed = await _showDeleteConfirmation(task);

    if (confirmed == true) {
      try {
        await ref.read(taskProvider.notifier).deleteTask(task.id);
        ref.read(taskStatisticsProvider.notifier).refresh();
        
        if (mounted) {
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

  Future<bool?> _showDeleteConfirmation(Task task) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
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

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    required this.onTap,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(context),
              const SizedBox(height: 12),
              _buildBottomRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        _buildStatusCheckbox(),
        const SizedBox(width: 12),
        Expanded(child: _buildTaskContent(context)),
        _buildPriorityBadge(),
      ],
    );
  }

  Widget _buildStatusCheckbox() {
    return GestureDetector(
      onTap: onToggleStatus,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: task.status == TaskStatus.completed
                ? Colors.green
                : Colors.grey,
            width: 2,
          ),
          color: task.status == TaskStatus.completed
              ? Colors.green
              : Colors.transparent,
        ),
        child: task.status == TaskStatus.completed
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildTaskContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTaskTitle(context),
        if (_hasDescription()) _buildTaskDescription(context),
      ],
    );
  }

  Widget _buildTaskTitle(BuildContext context) {
    return Text(
      task.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
            color: task.status == TaskStatus.completed
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : null,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTaskDescription(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          task.description!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  bool _hasDescription() => task.description != null && task.description!.isNotEmpty;

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: task.priority.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(task.priority.icon, size: 12, color: task.priority.color),
          const SizedBox(width: 4),
          Text(
            task.priority.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: task.priority.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    return Row(
      children: [
        if (task.dueDate != null) _buildDueDateInfo(context),
        const Spacer(),
        _buildStatusBadge(),
        const SizedBox(width: 8),
        _buildDeleteButton(),
      ],
    );
  }

  Widget _buildDueDateInfo(BuildContext context) {
    final (color, text) = _getDueDateInfo(context);
    
    return Row(
      children: [
        Icon(Iconsax.calendar, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: task.isOverdue || task.isDueToday
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  (Color, String) _getDueDateInfo(BuildContext context) {
    if (task.isOverdue) {
      return (Colors.red, 'Overdue');
    } else if (task.isDueToday) {
      return (Colors.orange, 'Due today');
    } else if (task.isDueTomorrow) {
      return (Theme.of(context).colorScheme.onSurfaceVariant, 'Due tomorrow');
    } else {
      return (
        Theme.of(context).colorScheme.onSurfaceVariant,
        DateFormat('MMM d').format(task.dueDate!)
      );
    }
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: task.status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: task.status.color,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Iconsax.trash, size: 14, color: Colors.red),
      ),
    );
  }
}