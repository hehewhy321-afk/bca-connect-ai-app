import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskStorageService {
  static const String _tasksBoxName = 'tasks';
  static const String _categoriesBoxName = 'task_categories';
  
  static Box<String>? _tasksBox;
  static Box<String>? _categoriesBox;

  static Future<void> initialize() async {
    try {
      _tasksBox = await Hive.openBox<String>(_tasksBoxName);
      _categoriesBox = await Hive.openBox<String>(_categoriesBoxName);
      
      // Initialize default categories if none exist
      if (_categoriesBox!.isEmpty) {
        await _initializeDefaultCategories();
      }
      
      debugPrint('TaskStorageService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing TaskStorageService: $e');
    }
  }

  static Future<void> _initializeDefaultCategories() async {
    try {
      for (final category in DefaultTaskCategories.categories) {
        await _categoriesBox!.put(category.id, jsonEncode(category.toJson()));
      }
      debugPrint('Default task categories initialized');
    } catch (e) {
      debugPrint('Error initializing default categories: $e');
    }
  }

  // Task CRUD operations
  static Future<void> saveTask(Task task) async {
    try {
      await _tasksBox!.put(task.id, jsonEncode(task.toJson()));
      debugPrint('Task saved: ${task.title}');
    } catch (e) {
      debugPrint('Error saving task: $e');
      throw Exception('Failed to save task');
    }
  }

  static Future<Task?> getTask(String id) async {
    try {
      final taskJson = _tasksBox!.get(id);
      if (taskJson != null) {
        return Task.fromJson(jsonDecode(taskJson));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting task: $e');
      return null;
    }
  }

  static Future<List<Task>> getAllTasks() async {
    try {
      final tasks = <Task>[];
      for (final taskJson in _tasksBox!.values) {
        try {
          final task = Task.fromJson(jsonDecode(taskJson));
          tasks.add(task);
        } catch (e) {
          debugPrint('Error parsing task: $e');
        }
      }
      
      // Sort by created date (newest first)
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    } catch (e) {
      debugPrint('Error getting all tasks: $e');
      return [];
    }
  }

  static Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) => task.status == status).toList();
    } catch (e) {
      debugPrint('Error getting tasks by status: $e');
      return [];
    }
  }

  static Future<List<Task>> getTasksByCategory(String categoryId) async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) => task.categoryId == categoryId).toList();
    } catch (e) {
      debugPrint('Error getting tasks by category: $e');
      return [];
    }
  }

  static Future<List<Task>> getTasksDueToday() async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) => task.isDueToday && task.status != TaskStatus.completed).toList();
    } catch (e) {
      debugPrint('Error getting tasks due today: $e');
      return [];
    }
  }

  static Future<List<Task>> getOverdueTasks() async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.where((task) => task.isOverdue).toList();
    } catch (e) {
      debugPrint('Error getting overdue tasks: $e');
      return [];
    }
  }

  static Future<void> updateTask(Task task) async {
    await saveTask(task);
  }

  static Future<void> deleteTask(String id) async {
    try {
      await _tasksBox!.delete(id);
      debugPrint('Task deleted: $id');
    } catch (e) {
      debugPrint('Error deleting task: $e');
      throw Exception('Failed to delete task');
    }
  }

  static Future<void> markTaskCompleted(String id) async {
    try {
      final task = await getTask(id);
      if (task != null) {
        final completedTask = task.copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await saveTask(completedTask);
      }
    } catch (e) {
      debugPrint('Error marking task completed: $e');
      throw Exception('Failed to mark task as completed');
    }
  }

  // Category CRUD operations
  static Future<void> saveCategory(TaskCategory category) async {
    try {
      await _categoriesBox!.put(category.id, jsonEncode(category.toJson()));
      debugPrint('Category saved: ${category.name}');
    } catch (e) {
      debugPrint('Error saving category: $e');
      throw Exception('Failed to save category');
    }
  }

  static Future<TaskCategory?> getCategory(String id) async {
    try {
      final categoryJson = _categoriesBox!.get(id);
      if (categoryJson != null) {
        return TaskCategory.fromJson(jsonDecode(categoryJson));
      }
      return null;
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }

  static Future<List<TaskCategory>> getAllCategories() async {
    try {
      final categories = <TaskCategory>[];
      for (final categoryJson in _categoriesBox!.values) {
        try {
          final category = TaskCategory.fromJson(jsonDecode(categoryJson));
          categories.add(category);
        } catch (e) {
          debugPrint('Error parsing category: $e');
        }
      }
      
      // Sort by name
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    } catch (e) {
      debugPrint('Error getting all categories: $e');
      return DefaultTaskCategories.categories;
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      await _categoriesBox!.delete(id);
      debugPrint('Category deleted: $id');
    } catch (e) {
      debugPrint('Error deleting category: $e');
      throw Exception('Failed to delete category');
    }
  }

  // Statistics
  static Future<Map<String, int>> getTaskStatistics() async {
    try {
      final allTasks = await getAllTasks();
      
      return {
        'total': allTasks.length,
        'pending': allTasks.where((t) => t.status == TaskStatus.pending).length,
        'inProgress': allTasks.where((t) => t.status == TaskStatus.inProgress).length,
        'completed': allTasks.where((t) => t.status == TaskStatus.completed).length,
        'overdue': allTasks.where((t) => t.isOverdue).length,
        'dueToday': allTasks.where((t) => t.isDueToday && t.status != TaskStatus.completed).length,
      };
    } catch (e) {
      debugPrint('Error getting task statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'completed': 0,
        'overdue': 0,
        'dueToday': 0,
      };
    }
  }

  // Search and filter
  static Future<List<Task>> searchTasks(String query) async {
    try {
      final allTasks = await getAllTasks();
      final lowercaseQuery = query.toLowerCase();
      
      return allTasks.where((task) {
        return task.title.toLowerCase().contains(lowercaseQuery) ||
               (task.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
               task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      debugPrint('Error searching tasks: $e');
      return [];
    }
  }

  // Import/Export functionality
  static Future<Map<String, dynamic>> exportData() async {
    try {
      final tasks = await getAllTasks();
      final categories = await getAllCategories();
      
      return {
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      throw Exception('Failed to export data');
    }
  }

  static Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await _tasksBox!.clear();
      await _categoriesBox!.clear();
      
      // Import categories
      if (data['categories'] != null) {
        for (final categoryData in data['categories']) {
          final category = TaskCategory.fromJson(categoryData);
          await saveCategory(category);
        }
      }
      
      // Import tasks
      if (data['tasks'] != null) {
        for (final taskData in data['tasks']) {
          final task = Task.fromJson(taskData);
          await saveTask(task);
        }
      }
      
      debugPrint('Data imported successfully');
    } catch (e) {
      debugPrint('Error importing data: $e');
      throw Exception('Failed to import data');
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    try {
      await _tasksBox!.clear();
      await _categoriesBox!.clear();
      await _initializeDefaultCategories();
      debugPrint('All task data cleared');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      throw Exception('Failed to clear data');
    }
  }
}