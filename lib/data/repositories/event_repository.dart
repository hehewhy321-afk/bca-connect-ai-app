import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/event.dart';
import 'dart:convert';

class EventRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  final ConnectivityService _connectivity = ConnectivityService();

  // Get all events with caching
  Future<List<Event>> getEvents({
    String? status,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${CacheKeys.events}_${status ?? 'all'}';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data (unless explicitly using cache)
    if (isOnline && !forceRefresh) {
      try {
        dynamic query = _client
            .from('events')
            .select()
            .order('start_date', ascending: true);

        if (status != null) {
          query = query.eq('status', status);
        }

        final response = await query;
        
        if (response.isEmpty) {
          debugPrint('No events found in database');
          return [];
        }
        
        debugPrint('Fetched ${response.length} events from database (online)');
        final events = (response as List).map((e) => Event.fromJson(e)).toList();
        
        // Cache the fresh results
        final jsonList = events.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.mediumCache,
        );
        
        return events;
      } catch (e) {
        debugPrint('Error fetching events: $e');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        debugPrint('Loaded ${jsonList.length} events from cache (offline or error)');
        return jsonList.map((e) => Event.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
    
    throw Exception('No internet connection and no cached data available');
  }

  // Get upcoming events
  Future<List<Event>> getUpcomingEvents({int limit = 50, bool forceRefresh = false}) async {
    const cacheKey = '${CacheKeys.events}_upcoming';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data
    if (isOnline) {
      try {
        final response = await _client
            .from('events')
            .select()
            .order('start_date', ascending: true);

        if (response.isEmpty) {
          debugPrint('No upcoming events found in database');
          return [];
        }
        
        debugPrint('Fetched ${response.length} upcoming events from database (online)');
        final events = (response as List).map((e) => Event.fromJson(e)).toList();
        
        // Cache the fresh results
        final jsonList = events.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.mediumCache,
        );
        
        return events;
      } catch (e) {
        debugPrint('Error fetching upcoming events: $e');
        // Fall through to cache on error
      }
    }

    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        debugPrint('Loaded ${jsonList.length} upcoming events from cache (offline or error)');
        return jsonList.map((e) => Event.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading upcoming events from cache: $e');
    }
    
    throw Exception('No internet connection and no cached data available');
  }

  // Get featured events
  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await _client
          .from('events')
          .select()
          .eq('is_featured', true)
          .order('start_date', ascending: true)
          .limit(5);

      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching featured events: $e');
      return [];
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String id) async {
    try {
      final response = await _client
          .from('events')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Event.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error fetching event: $e');
      return null;
    }
  }

  // Stream events (realtime)
  Stream<List<Event>> streamEvents() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('start_date')
        .map((data) => data.map((e) => Event.fromJson(e)).toList());
  }

  // Register for event
  Future<void> registerForEvent({
    required String eventId,
    String? teamName,
    List<Map<String, dynamic>>? teamMembers,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('event_registrations').insert({
      'event_id': eventId,
      'user_id': userId,
      'team_name': teamName,
      'team_members': teamMembers ?? [],
    });
  }

  // Get user registrations
  Future<List<Map<String, dynamic>>> getUserRegistrations() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('event_registrations')
          .select('*, events(*)')
          .eq('user_id', userId)
          .order('registered_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching user registrations: $e');
      return [];
    }
  }

  // Check if user is registered for event
  Future<bool> isUserRegistered(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client
          .from('event_registrations')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Error checking registration: $e');
      return false;
    }
  }

  // Submit or update event feedback
  Future<void> submitFeedback({
    required String eventId,
    required int rating,
    String? feedback,
    bool isAnonymous = false,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if feedback already exists
      final existing = await _client
          .from('event_feedback')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing feedback
        await _client
            .from('event_feedback')
            .update({
              'rating': rating,
              'feedback': feedback,
              'is_anonymous': isAnonymous,
            })
            .eq('id', existing['id']);
        debugPrint('Updated feedback for event $eventId');
      } else {
        // Insert new feedback
        await _client.from('event_feedback').insert({
          'event_id': eventId,
          'user_id': userId,
          'rating': rating,
          'feedback': feedback,
          'is_anonymous': isAnonymous,
        });
        debugPrint('Submitted new feedback for event $eventId');
      }
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  // Check if user has given feedback for event
  Future<Map<String, dynamic>?> getUserFeedback(String eventId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('event_feedback')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user feedback: $e');
      return null;
    }
  }
}
