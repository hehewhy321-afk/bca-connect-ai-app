import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cacheBoxName = 'app_cache';
  static Box? _cacheBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // Check if cache exists
  static bool has(String key) {
    return _cacheBox?.containsKey(key) ?? false;
  }

  // Save data to cache
  static Future<void> set(String key, dynamic data, {Duration? duration}) async {
    try {
      await _cacheBox?.put(key, data);
      await _cacheBox?.put('${key}_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving cache: $e');
    }
  }

  // Get data from cache
  static T? get<T>(String key) {
    try {
      return _cacheBox?.get(key) as T?;
    } catch (e) {
      debugPrint('Error reading cache: $e');
      return null;
    }
  }

  // Check if cache is valid (less than 24 hours old)
  static bool isCacheValid(String key, {Duration maxAge = const Duration(hours: 24)}) {
    try {
      final timestampString = _cacheBox?.get('${key}_timestamp');
      if (timestampString != null) {
        final timestamp = DateTime.parse(timestampString);
        return DateTime.now().difference(timestamp) < maxAge;
      }
    } catch (e) {
      debugPrint('Error checking cache validity: $e');
    }
    return false;
  }

  // Clear specific cache
  static Future<void> clearCache(String key) async {
    await _cacheBox?.delete(key);
    await _cacheBox?.delete('${key}_timestamp');
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    await _cacheBox?.clear();
  }
}

// Cache Keys
class CacheKeys {
  static const String events = 'events_cache';
  static const String announcements = 'announcements_cache';
  static const String notifications = 'notifications_cache';
  static const String resources = 'resources_cache';
  static const String forumPosts = 'forum_posts_cache';
  static const String profile = 'profile_cache';
  
  // Cache durations
  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(hours: 24);
}
