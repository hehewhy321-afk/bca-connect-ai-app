import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/forum_repository.dart';
import '../../data/models/forum_post.dart';
import '../../data/mock/mock_data.dart';

// Forum Repository Provider
final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});

// All Forum Posts Provider with Mock Data Fallback
final forumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  try {
    final posts = await ref.watch(forumRepositoryProvider).getPosts();
    // If no posts from backend, use mock data
    if (posts.isEmpty) {
      return MockData.getMockForumPosts();
    }
    return posts;
  } catch (e) {
    debugPrint('Error loading forum posts, using mock data: $e');
    // Return mock data on error
    return MockData.getMockForumPosts();
  }
});

// Forum Posts by Category Provider
final forumPostsByCategoryProvider = FutureProvider.family<List<ForumPost>, String?>((ref, category) async {
  try {
    return await ref.watch(forumRepositoryProvider).getPosts(category: category);
  } catch (e) {
    debugPrint('Error loading forum posts by category: $e');
    return MockData.getMockForumPosts();
  }
});

// Forum Post Detail Provider
final forumPostDetailProvider = FutureProvider.family<ForumPost?, String>((ref, id) async {
  try {
    return await ref.watch(forumRepositoryProvider).getPostById(id);
  } catch (e) {
    debugPrint('Error loading forum post detail: $e');
    return null;
  }
});

// Forum Comments Provider
final forumCommentsProvider = FutureProvider.family<List<ForumComment>, String>((ref, postId) async {
  try {
    return await ref.watch(forumRepositoryProvider).getComments(postId);
  } catch (e) {
    debugPrint('Error loading forum comments: $e');
    return [];
  }
});

