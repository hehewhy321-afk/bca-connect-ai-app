import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/models/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final activeAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    // Force refresh on first load to ensure we get fresh data
    return await ref.watch(announcementRepositoryProvider).getActiveAnnouncements(forceRefresh: true);
  } catch (e) {
    debugPrint('Error loading announcements: $e');
    return [];
  }
});

final allAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    // Force refresh on first load to ensure we get fresh data
    return await ref.watch(announcementRepositoryProvider).getAllAnnouncements(forceRefresh: true);
  } catch (e) {
    debugPrint('Error loading all announcements: $e');
    return [];
  }
});

