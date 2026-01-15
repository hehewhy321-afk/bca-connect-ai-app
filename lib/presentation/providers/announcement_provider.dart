import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/models/announcement.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final activeAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    return await ref.watch(announcementRepositoryProvider).getActiveAnnouncements();
  } catch (e) {
    debugPrint('Error loading announcements: $e');
    return [];
  }
});

final allAnnouncementsProvider = FutureProvider<List<Announcement>>((ref) async {
  try {
    return await ref.watch(announcementRepositoryProvider).getAllAnnouncements();
  } catch (e) {
    debugPrint('Error loading all announcements: $e');
    return [];
  }
});

