import 'package:flutter/foundation.dart';
import '../models/announcement.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import 'dart:convert';

class AnnouncementRepository {
  final _supabase = SupabaseConfig.client;
  final ConnectivityService _connectivity = ConnectivityService();

  Future<List<Announcement>> getActiveAnnouncements({bool forceRefresh = false}) async {
    const cacheKey = '${CacheKeys.announcements}_active';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data
    if (isOnline) {
      try {
        debugPrint('Fetching announcements from database...');
        final response = await _supabase
            .from('announcements')
            .select()
            .order('created_at', ascending: false)
            .limit(10);

        debugPrint('Raw announcements response: $response');
        debugPrint('Response type: ${response.runtimeType}');
        debugPrint('Response length: ${(response as List).length}');

        final allAnnouncements = (response as List)
            .map((json) {
              debugPrint('Processing announcement: $json');
              return Announcement.fromJson(json);
            })
            .toList();
        
        debugPrint('Total announcements before filtering: ${allAnnouncements.length}');
        
        final announcements = allAnnouncements.where((announcement) {
          // Filter out expired announcements
          if (announcement.expiresAt != null) {
            final isExpired = announcement.expiresAt!.isBefore(DateTime.now());
            debugPrint('Announcement ${announcement.title}: expires=${announcement.expiresAt}, isExpired=$isExpired');
            return !isExpired && announcement.isActive;
          }
          debugPrint('Announcement ${announcement.title}: no expiry, isActive=${announcement.isActive}');
          return announcement.isActive;
        }).toList();
        
        debugPrint('Active announcements after filtering: ${announcements.length}');
        debugPrint('Fetched ${announcements.length} announcements from database (online)');
        
        // Cache the fresh results
        final jsonList = announcements.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.shortCache,
        );
        
        return announcements;
      } catch (e, stackTrace) {
        debugPrint('Error fetching announcements: $e');
        debugPrint('Stack trace: $stackTrace');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        debugPrint('Loaded ${jsonList.length} announcements from cache (offline or error)');
        return jsonList.map((e) => Announcement.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading announcements from cache: $e');
    }
    
    throw Exception('No internet connection and no cached data available');
  }

  Future<List<Announcement>> getAllAnnouncements({bool forceRefresh = false}) async {
    const cacheKey = '${CacheKeys.announcements}_all';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('announcements')
            .select()
            .order('created_at', ascending: false);

        final announcements = (response as List)
            .map((json) => Announcement.fromJson(json))
            .toList();
        
        debugPrint('Fetched ${announcements.length} all announcements from database (online)');
        
        // Cache the fresh results
        final jsonList = announcements.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.shortCache,
        );
        
        return announcements;
      } catch (e) {
        debugPrint('Error fetching all announcements: $e');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        debugPrint('Loaded ${jsonList.length} all announcements from cache (offline or error)');
        return jsonList.map((e) => Announcement.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading all announcements from cache: $e');
    }
    
    throw Exception('No internet connection and no cached data available');
  }
}
