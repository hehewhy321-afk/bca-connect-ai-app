import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';

class NotificationListenerService {
  static final NotificationListenerService _instance = NotificationListenerService._internal();
  factory NotificationListenerService() => _instance;
  NotificationListenerService._internal();

  StreamSubscription? _subscription;
  final Set<String> _processedNotifications = {};
  DateTime? _lastCheckTime;

  void startListening() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      debugPrint('Cannot start notification listener: No user logged in');
      return;
    }

    _lastCheckTime = DateTime.now();
    debugPrint('Starting notification listener for user: ${user.id}');

    // Listen to new notifications in real-time
    _subscription = SupabaseConfig.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          debugPrint('Notification stream update received: ${data.length} notifications');
          
          for (var notification in data) {
            // Filter for current user
            if (notification['user_id'] != user.id) continue;
            
            final id = notification['id'] as String;
            final isRead = notification['is_read'] as bool? ?? false;
            final createdAt = notification['created_at'] as String?;
            
            // Check if notification is new (created after we started listening)
            bool isNew = false;
            if (createdAt != null && _lastCheckTime != null) {
              final notificationTime = DateTime.parse(createdAt);
              isNew = notificationTime.isAfter(_lastCheckTime!);
            }
            
            debugPrint('Notification $id: isNew=$isNew, isRead=$isRead, processed=${_processedNotifications.contains(id)}');
            
            // Show notification if it's new, unread, and not yet processed
            if (!_processedNotifications.contains(id) && !isRead && isNew) {
              debugPrint('Showing new notification: $id');
              _processedNotifications.add(id);
              _showLocalNotification(notification);
            }
          }
        }, onError: (error) {
          debugPrint('Notification stream error: $error');
        });
  }

  Future<void> _showLocalNotification(Map<String, dynamic> notification) async {
    final title = notification['title'] as String? ?? 'New Notification';
    final message = notification['message'] as String? ?? '';
    final type = notification['type'] as String? ?? 'info';
    
    debugPrint('Triggering local notification: $title');
    
    // Determine route based on type
    String? route;
    switch (type) {
      case 'event':
        route = '/events';
        break;
      case 'forum':
        route = '/forum';
        break;
      default:
        route = '/notifications';
    }

    // Show notification with sound
    try {
      await NotificationService().showNotification(
        title: title,
        body: message,
        payload: route,
      );
      debugPrint('Local notification triggered successfully');
    } catch (e) {
      debugPrint('Error triggering local notification: $e');
    }
  }

  void stopListening() {
    debugPrint('Stopping notification listener');
    _subscription?.cancel();
    _subscription = null;
  }

  void clearProcessedNotifications() {
    debugPrint('Clearing processed notifications');
    _processedNotifications.clear();
    _lastCheckTime = DateTime.now();
  }
}
