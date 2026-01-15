import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../../core/config/supabase_config.dart';

class AnnouncementRepository {
  final _supabase = SupabaseConfig.client;

  Future<List<Announcement>> getActiveAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(5);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .where((announcement) {
            // Filter out expired announcements
            if (announcement.expiresAt != null) {
              return announcement.expiresAt!.isAfter(DateTime.now());
            }
            return announcement.isActive;
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      return [];
    }
  }

  Future<List<Announcement>> getAllAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all announcements: $e');
      return [];
    }
  }
}
