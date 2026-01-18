import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import '../models/resource.dart';
import 'dart:convert';

class ResourceRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  final ConnectivityService _connectivity = ConnectivityService();

  // Get all resources with caching
  Future<List<Resource>> getResources({
    String? category,
    String? type,
    int limit = 20,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${CacheKeys.resources}_${category ?? 'all'}_${type ?? 'all'}_$offset';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online, always fetch fresh data
    if (isOnline) {
      try {
        dynamic query = _client
            .from('resources')
            .select()
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        if (category != null) {
          query = query.eq('category', category);
        }
        if (type != null) {
          query = query.eq('type', type);
        }

        final response = await query;
        final resources = (response as List).map((e) => Resource.fromJson(e)).toList();
        
        debugPrint('Fetched ${resources.length} resources from database (online)');
        
        // Cache the fresh results
        final jsonList = resources.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.mediumCache,
        );
        
        return resources;
      } catch (e) {
        debugPrint('Error fetching resources: $e');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        debugPrint('Loaded ${jsonList.length} resources from cache (offline or error)');
        return jsonList.map((e) => Resource.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading resources from cache: $e');
    }
    
    throw Exception('No internet connection and no cached data available');
  }

  // Get resource by ID
  Future<Resource?> getResourceById(String id) async {
    try {
      final response = await _client
          .from('resources')
          .select()
          .eq('id', id)
          .maybeSingle();

      return response != null ? Resource.fromJson(response) : null;
    } catch (e) {
      debugPrint('Error fetching resource: $e');
      return null;
    }
  }

  // Increment download count
  Future<void> incrementDownloads(String id) async {
    try {
      await _client.rpc('increment_resource_downloads', params: {'resource_id_param': id});
    } catch (e) {
      debugPrint('Error incrementing downloads: $e');
    }
  }

  // Search resources
  Future<List<Resource>> searchResources(String query) async {
    try {
      final response = await _client
          .from('resources')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List).map((e) => Resource.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error searching resources: $e');
      return [];
    }
  }
}
