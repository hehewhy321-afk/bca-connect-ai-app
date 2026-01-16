import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheService {
  static const String _cacheBoxName = 'app_cache';
  static const Duration _defaultCacheDuration = Duration(hours: 1);
  
  static Box? _cacheBox;

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // Get cached data
  static T? get<T>(String key) {
    if (_cacheBox == null) return null;
    
    final cached = _cacheBox!.get(key);
    if (cached == null) return null;

    final data = cached as Map;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    final duration = data['duration'] as int;

    // Check if cache is expired
    if (DateTime.now().difference(timestamp).inMilliseconds > duration) {
      _cacheBox!.delete(key);
      return null;
    }

    // Return cached value
    if (T == String) {
      return data['value'] as T;
    } else if (T == List) {
      return (jsonDecode(data['value'] as String) as List).cast<dynamic>() as T;
    } else if (T == Map) {
      return jsonDecode(data['value'] as String) as T;
    }
    
    return data['value'] as T;
  }

  // Set cache data
  static Future<void> set(
    String key,
    dynamic value, {
    Duration? duration,
  }) async {
    if (_cacheBox == null) return;

    final cacheDuration = duration ?? _defaultCacheDuration;
    
    String valueToStore;
    if (value is String) {
      valueToStore = value;
    } else if (value is List || value is Map) {
      valueToStore = jsonEncode(value);
    } else {
      valueToStore = value.toString();
    }

    await _cacheBox!.put(key, {
      'value': valueToStore,
      'timestamp': DateTime.now().toIso8601String(),
      'duration': cacheDuration.inMilliseconds,
    });
  }

  // Clear specific cache
  static Future<void> clear(String key) async {
    if (_cacheBox == null) return;
    await _cacheBox!.delete(key);
  }

  // Clear all cache
  static Future<void> clearAll() async {
    if (_cacheBox == null) return;
    await _cacheBox!.clear();
  }

  // Check if cache exists and is valid
  static bool has(String key) {
    if (_cacheBox == null) return false;
    
    final cached = _cacheBox!.get(key);
    if (cached == null) return false;

    final data = cached as Map;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    final duration = data['duration'] as int;

    return DateTime.now().difference(timestamp).inMilliseconds <= duration;
  }

  // Get cache age
  static Duration? getCacheAge(String key) {
    if (_cacheBox == null) return null;
    
    final cached = _cacheBox!.get(key);
    if (cached == null) return null;

    final data = cached as Map;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    
    return DateTime.now().difference(timestamp);
  }
}

// Cache keys constants
class CacheKeys {
  static const String events = 'events_list';
  static const String forumPosts = 'forum_posts_list';
  static const String resources = 'resources_list';
  static const String notices = 'notices_list';
  static const String certificates = 'certificates_list';
  static const String communityMembers = 'community_members_list';
  static const String userProfile = 'user_profile';
  static const String notifications = 'notifications_list';
  
  // Cache durations
  static const Duration shortCache = Duration(minutes: 15);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(hours: 6);
}
