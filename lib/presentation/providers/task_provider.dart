import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../data/services/task_storage_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/notification_service.dart';

// Task providers
final taskProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>((ref) {
      return TaskNotifier();
    });

final taskCategoriesProvider =
    StateNotifierProvider<
      TaskCategoriesNotifier,
      AsyncValue<List<TaskCategory>>
    >((ref) {
      return TaskCategoriesNotifier();
    });

final taskStatisticsProvider =
    StateNotifierProvider<TaskStatisticsNotifier, AsyncValue<Map<String, int>>>(
      (ref) {
        return TaskStatisticsNotifier();
      },
    );

// Filter providers
final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter());

final filteredTasksProvider = Provider<AsyncValue<List<Task>>>((ref) {
  final tasks = ref.watch(taskProvider);
  final filter = ref.watch(taskFilterProvider);

  return tasks.when(
    data: (taskList) {
      var filtered = taskList.where((task) {
        // Status filter
        if (filter.status != null && task.status != filter.status) {
          return false;
        }

        // Category filter
        if (filter.categoryId != null && task.categoryId != filter.categoryId) {
          return false;
        }

        // Priority filter
        if (filter.priority != null && task.priority != filter.priority) {
          return false;
        }

        // Search query
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          if (!task.title.toLowerCase().contains(query) &&
              !(task.description?.toLowerCase().contains(query) ?? false) &&
              !task.tags.any((tag) => tag.toLowerCase().contains(query))) {
            return false;
          }
        }

        // Due date filter
        if (filter.showOverdueOnly && !task.isOverdue) {
          return false;
        }

        if (filter.showDueTodayOnly && !task.isDueToday) {
          return false;
        }

        return true;
      }).toList();

      // Sort
      switch (filter.sortBy) {
        case TaskSortBy.dueDate:
          filtered.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
          break;
        case TaskSortBy.priority:
          filtered.sort((a, b) => b.priority.index.compareTo(a.priority.index));
          break;
        case TaskSortBy.title:
          filtered.sort((a, b) => a.title.compareTo(b.title));
          break;
        case TaskSortBy.createdDate:
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Task notifier
class TaskNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  TaskNotifier() : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      state = const AsyncValue.loading();
      final tasks = await TaskStorageService.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await TaskStorageService.saveTask(task);
      await _syncTaskNotifications(task);
      await loadTasks(); // Refresh the list
    } catch (error) {
      debugPrint('Error adding task: $error');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await TaskStorageService.updateTask(task);
      await _syncTaskNotifications(task);
      await loadTasks(); // Refresh the list
    } catch (error) {
      debugPrint('Error updating task: $error');
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final task = await TaskStorageService.getTask(taskId);
      if (task != null) {
        final baseId = (int.tryParse(task.id) ?? task.id.hashCode).abs();
        final reminderId = (baseId % 100000000) * 2;
        final deadlineId = reminderId + 1;
        await NotificationService().cancelNotification(reminderId);
        await NotificationService().cancelNotification(deadlineId);
      }
      await TaskStorageService.deleteTask(taskId);
      await loadTasks(); // Refresh the list
    } catch (error) {
      debugPrint('Error deleting task: $error');
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(String taskId) async {
    try {
      final task = await TaskStorageService.getTask(taskId);
      if (task != null) {
        final isCompleting = task.status != TaskStatus.completed;
        final newStatus = isCompleting
            ? TaskStatus.completed
            : TaskStatus.pending;

        final updatedTask = task.copyWith(
          status: newStatus,
          completedAt: newStatus == TaskStatus.completed
              ? DateTime.now()
              : null,
        );

        await TaskStorageService.updateTask(updatedTask);
        await _syncTaskNotifications(updatedTask);

        if (isCompleting) {
          _playCompletionFeedback(task.title);
        }

        await loadTasks(); // Refresh the list
      }
    } catch (error) {
      debugPrint('Error toggling task status: $error');
      rethrow;
    }
  }

  Future<void> markTaskCompleted(String taskId) async {
    try {
      final task = await TaskStorageService.getTask(taskId);
      await TaskStorageService.markTaskCompleted(taskId);
      if (task != null) {
        final baseId = (int.tryParse(task.id) ?? task.id.hashCode).abs();
        final reminderId = (baseId % 100000000) * 2;
        final deadlineId = reminderId + 1;
        await NotificationService().cancelNotification(reminderId);
        await NotificationService().cancelNotification(deadlineId);
        _playCompletionFeedback(task.title);
      }
      await loadTasks(); // Refresh the list
    } catch (error) {
      debugPrint('Error marking task completed: $error');
      rethrow;
    }
  }

  Future<void> _syncTaskNotifications(Task task) async {
    final baseId = (int.tryParse(task.id) ?? task.id.hashCode).abs();
    final reminderId = (baseId % 100000000) * 2;
    final deadlineId = reminderId + 1;

    // Always cancel existing first to avoid duplicates or orphaned reminders
    await NotificationService().cancelNotification(reminderId);
    await NotificationService().cancelNotification(deadlineId);

    // Only schedule if not completed
    if (task.status != TaskStatus.completed) {
      final now = DateTime.now();

      // 1. Schedule Reminder
      if (task.reminderDate != null && task.reminderDate!.isAfter(now)) {
        await NotificationService().scheduleNotification(
          id: reminderId,
          title: 'Task Reminder: ${task.title}',
          body: task.description ?? 'Time to work on your task!',
          scheduledDate: task.reminderDate!,
          payload: 'task_${task.id}',
        );
      }

      // 2. Schedule Deadline (Overdue)
      if (task.dueDate != null && task.dueDate!.isAfter(now)) {
        await NotificationService().scheduleNotification(
          id: deadlineId,
          title: 'Task Due Now: ${task.title}',
          body: 'This task is due right now. Don\'t let it expire!',
          scheduledDate: task.dueDate!,
          payload: 'task_${task.id}',
        );
      }
    }
  }

  void _playCompletionFeedback(String taskTitle) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/for-study.mp3'));
      await NotificationService().showNotification(
        title: 'Task Completed!',
        body: 'Great job completing: $taskTitle',
      );
    } catch (e) {
      debugPrint('Error playing completion feedback: $e');
    }
  }
}

// Categories notifier
class TaskCategoriesNotifier
    extends StateNotifier<AsyncValue<List<TaskCategory>>> {
  TaskCategoriesNotifier() : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      state = const AsyncValue.loading();
      final categories = await TaskStorageService.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> addCategory(TaskCategory category) async {
    try {
      await TaskStorageService.saveCategory(category);
      await loadCategories(); // Refresh the list
    } catch (error) {
      debugPrint('Error adding category: $error');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await TaskStorageService.deleteCategory(categoryId);
      await loadCategories(); // Refresh the list
    } catch (error) {
      debugPrint('Error deleting category: $error');
      rethrow;
    }
  }
}

// Statistics notifier
class TaskStatisticsNotifier
    extends StateNotifier<AsyncValue<Map<String, int>>> {
  TaskStatisticsNotifier() : super(const AsyncValue.loading()) {
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    try {
      state = const AsyncValue.loading();
      final stats = await TaskStorageService.getTaskStatistics();
      state = AsyncValue.data(stats);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> refresh() async {
    await loadStatistics();
  }
}

// Filter and sort models
class TaskFilter {
  final TaskStatus? status;
  final String? categoryId;
  final TaskPriority? priority;
  final String searchQuery;
  final bool showOverdueOnly;
  final bool showDueTodayOnly;
  final TaskSortBy sortBy;

  TaskFilter({
    this.status,
    this.categoryId,
    this.priority,
    this.searchQuery = '',
    this.showOverdueOnly = false,
    this.showDueTodayOnly = false,
    this.sortBy = TaskSortBy.createdDate,
  });

  TaskFilter copyWith({
    TaskStatus? status,
    String? categoryId,
    TaskPriority? priority,
    String? searchQuery,
    bool? showOverdueOnly,
    bool? showDueTodayOnly,
    TaskSortBy? sortBy,
  }) {
    return TaskFilter(
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      searchQuery: searchQuery ?? this.searchQuery,
      showOverdueOnly: showOverdueOnly ?? this.showOverdueOnly,
      showDueTodayOnly: showDueTodayOnly ?? this.showDueTodayOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return status != null ||
        categoryId != null ||
        priority != null ||
        searchQuery.isNotEmpty ||
        showOverdueOnly ||
        showDueTodayOnly;
  }
}

enum TaskSortBy { createdDate, dueDate, priority, title }
