import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class QuickAction {
  final String id;
  final IconData icon;
  final String title;
  final Gradient gradient;
  final String route;
  final QuickActionType type;

  const QuickAction({
    required this.id,
    required this.icon,
    required this.title,
    required this.gradient,
    required this.route,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'route': route, 'type': type.name};
  }

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final defaultAction = _getDefaultAction(id);

    return QuickAction(
      id: id,
      icon: defaultAction.icon,
      title: json['title'] as String,
      gradient: defaultAction.gradient,
      route: json['route'] as String,
      type: QuickActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => defaultAction.type,
      ),
    );
  }

  static QuickAction _getDefaultAction(String id) {
    return _defaultActions.firstWhere((action) => action.id == id);
  }

  static const List<QuickAction> _defaultActions = [
    QuickAction(
      id: 'courses',
      icon: Iconsax.video_play,
      title: 'Courses',
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/courses',
      type: QuickActionType.large,
    ),
    QuickAction(
      id: 'study_planner',
      icon: Iconsax.book_1,
      title: 'Study Planner',
      gradient: LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/study',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'notices',
      icon: Iconsax.document_text,
      title: 'Notices',
      gradient: LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/notices',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'pomodoro',
      icon: Iconsax.timer_1,
      title: 'Pomodoro Timer',
      gradient: LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/pomodoro',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'finance',
      icon: Iconsax.wallet_money,
      title: 'Finance Tracker',
      gradient: LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/finance',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'task_manager',
      icon: Iconsax.task_square,
      title: 'Tasks',
      gradient: LinearGradient(
        colors: [Color(0xFF00897B), Color(0xFF00BFA5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/tasks',
      type: QuickActionType.large,
    ),
    QuickAction(
      id: 'nepali_calendar',
      icon: Iconsax.calendar_2,
      title: 'नेपाली पात्रो',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF8A50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/calendar',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'community',
      icon: Iconsax.people,
      title: 'Community Hub',
      gradient: LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/community',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'algorithm_games',
      icon: Iconsax.game,
      title: 'Algorithm Games',
      gradient: LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      route: '/algorithm-game',
      type: QuickActionType.horizontal,
    ),
    QuickAction(
      id: 'fun_zone',
      icon: Iconsax.emoji_happy,
      title: 'Fun Zone-Games',
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      route: '/fun-zone',
      type: QuickActionType.horizontal,
    ),
  ];
}

enum QuickActionType {
  large, // Large square card
  horizontal, // Small horizontal card
  small, // Small card (नेपाली पात्रो)
  medium, // Medium card (Community Hub)
  wide, // Full width card
}

class QuickActionsService {
  static const String _quickActionsKey = 'quick_actions_order';
  static const String _customizationEnabledKey =
      'quick_actions_customization_enabled';

  // Get ordered quick actions
  Future<List<QuickAction>> getOrderedQuickActions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_quickActionsKey);

    if (jsonString == null) {
      // Return default order
      return QuickAction._defaultActions;
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      final orderedActions = <QuickAction>[];

      for (final json in jsonList) {
        try {
          final action = QuickAction.fromJson(json);
          orderedActions.add(action);
        } catch (e) {
          // Skip invalid actions
          continue;
        }
      }

      // Ensure all default actions are present
      final defaultActions = QuickAction._defaultActions;
      for (final defaultAction in defaultActions) {
        if (!orderedActions.any((action) => action.id == defaultAction.id)) {
          orderedActions.add(defaultAction);
        }
      }

      return orderedActions;
    } catch (e) {
      // Return default order if parsing fails
      return QuickAction._defaultActions;
    }
  }

  // Save ordered quick actions
  Future<void> saveOrderedQuickActions(List<QuickAction> actions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = actions.map((action) => action.toJson()).toList();
    await prefs.setString(_quickActionsKey, jsonEncode(jsonList));
  }

  // Check if customization is enabled
  Future<bool> isCustomizationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_customizationEnabledKey) ?? false;
  }

  // Enable/disable customization
  Future<void> setCustomizationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customizationEnabledKey, enabled);
  }

  // Reset to default order
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quickActionsKey);
  }
}
