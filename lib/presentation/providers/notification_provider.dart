import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/supabase_config.dart';

// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    return Stream.value(0);
  }

  return SupabaseConfig.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .map((data) {
        final userNotifications = data.where((n) => 
          n['user_id'] == user.id && n['is_read'] == false
        ).toList();
        return userNotifications.length;
      });
});

// Provider for all notifications
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return SupabaseConfig.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .map((data) {
        final userNotifications = data.where((n) => n['user_id'] == user.id).toList();
        userNotifications.sort((a, b) {
          final aTime = DateTime.parse(a['created_at']);
          final bTime = DateTime.parse(b['created_at']);
          return bTime.compareTo(aTime);
        });
        return List<Map<String, dynamic>>.from(userNotifications);
      });
});
