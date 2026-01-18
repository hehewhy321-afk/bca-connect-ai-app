import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/user_profile.dart';
import 'dart:convert';

class UserRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  final ConnectivityService _connectivity = ConnectivityService();

  // Get user profile with caching
  Future<UserProfile?> getUserProfile(String userId, {bool forceRefresh = false}) async {
    final cacheKey = '${CacheKeys.profile}_$userId';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data
    if (isOnline) {
      try {
        final response = await _client
            .from('profiles')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (response == null) return null;
        
        final profile = UserProfile.fromJson(response);
        
        debugPrint('Fetched user profile from database (online)');
        
        // Cache the fresh result
        await CacheService.set(
          cacheKey,
          jsonEncode(profile.toJson()),
          duration: CacheKeys.longCache,
        );
        
        return profile;
      } catch (e) {
        debugPrint('Error fetching user profile: $e');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        debugPrint('Loaded user profile from cache (offline or error)');
        return UserProfile.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      debugPrint('Error loading profile from cache: $e');
    }
    
    return null;
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return getUserProfile(userId);
  }

  // Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('user_id', userId);
  }

  // Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  // Stream user profile
  Stream<UserProfile?> streamUserProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) return null;
          return UserProfile.fromJson(data.first);
        });
  }
}
