import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/resource_repository.dart';
import '../../data/models/resource.dart';
import '../../data/mock/mock_data.dart';

// Resource Repository Provider
final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository();
});

// All Resources Provider with Mock Data Fallback
final resourcesProvider = FutureProvider<List<Resource>>((ref) async {
  try {
    final resources = await ref.watch(resourceRepositoryProvider).getResources();
    // If no resources from backend, use mock data
    if (resources.isEmpty) {
      return MockData.getMockResources();
    }
    return resources;
  } catch (e) {
    debugPrint('Error loading resources, using mock data: $e');
    // Return mock data on error
    return MockData.getMockResources();
  }
});

// Resources by Category Provider
final resourcesByCategoryProvider = FutureProvider.family<List<Resource>, String?>((ref, category) async {
  try {
    return await ref.watch(resourceRepositoryProvider).getResources(category: category);
  } catch (e) {
    debugPrint('Error loading resources by category: $e');
    return MockData.getMockResources();
  }
});

// Resource Detail Provider
final resourceDetailProvider = FutureProvider.family<Resource?, String>((ref, id) async {
  try {
    return await ref.watch(resourceRepositoryProvider).getResourceById(id);
  } catch (e) {
    debugPrint('Error loading resource detail: $e');
    return null;
  }
});

