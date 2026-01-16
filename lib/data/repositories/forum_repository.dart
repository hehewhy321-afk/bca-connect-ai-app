import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/forum_post.dart';

class ForumRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get all posts
  Future<List<ForumPost>> getPosts({
    String? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic query = _client
          .from('forum_posts')
          .select('*, comments_count:forum_replies(count)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query;
      
      // Fetch user names separately for each post
      final posts = <ForumPost>[];
      for (var postData in response as List) {
        final data = Map<String, dynamic>.from(postData);
        
        // Extract comment count from the nested response
        if (data['comments_count'] != null && data['comments_count'] is List) {
          final countList = data['comments_count'] as List;
          data['comments_count'] = countList.isNotEmpty ? countList[0]['count'] ?? 0 : 0;
        } else {
          data['comments_count'] = 0;
        }
        
        // Try to fetch user profile
        try {
          final profile = await _client
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('user_id', data['user_id'])
              .maybeSingle();
          
          if (profile != null) {
            data['user_name'] = profile['full_name'];
            data['user_avatar'] = profile['avatar_url'];
          }
        } catch (e) {
          // If profile fetch fails, continue without user data
          debugPrint('Error fetching profile for post: $e');
        }
        
        posts.add(ForumPost.fromJson(data));
      }
      
      return posts;
    } catch (e) {
      debugPrint('Error fetching forum posts: $e');
      return [];
    }
  }

  // Get post by ID
  Future<ForumPost?> getPostById(String id) async {
    try {
      final response = await _client
          .from('forum_posts')
          .select('*, comments_count:forum_replies(count)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      
      final data = Map<String, dynamic>.from(response);
      
      // Extract comment count from the nested response
      if (data['comments_count'] != null && data['comments_count'] is List) {
        final countList = data['comments_count'] as List;
        data['comments_count'] = countList.isNotEmpty ? countList[0]['count'] ?? 0 : 0;
      } else {
        data['comments_count'] = 0;
      }
      
      // Fetch user profile separately
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('user_id', data['user_id'])
            .maybeSingle();
        
        if (profile != null) {
          data['user_name'] = profile['full_name'];
          data['user_avatar'] = profile['avatar_url'];
        }
      } catch (e) {
        debugPrint('Error fetching profile for post: $e');
      }
      
      // Increment view count
      try {
        await _client
            .from('forum_posts')
            .update({'views': (data['views'] ?? 0) + 1})
            .eq('id', id);
      } catch (e) {
        debugPrint('Error incrementing view count: $e');
      }
      
      return ForumPost.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching post: $e');
      return null;
    }
  }

  // Create post
  Future<void> createPost({
    required String title,
    required String content,
    required String category,
    List<String> tags = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('forum_posts').insert({
      'user_id': userId,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
    });
  }

  // Get comments for a post
  Future<List<ForumComment>> getComments(String postId) async {
    try {
      final response = await _client
          .from('forum_replies')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      // Fetch user names separately for each comment
      final comments = <ForumComment>[];
      for (var commentData in response as List) {
        final data = Map<String, dynamic>.from(commentData);
        
        // Try to fetch user profile
        try {
          final profile = await _client
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('user_id', data['user_id'])
              .maybeSingle();
          
          if (profile != null) {
            data['user_name'] = profile['full_name'];
            data['user_avatar'] = profile['avatar_url'];
          }
        } catch (e) {
          debugPrint('Error fetching profile for comment: $e');
        }
        
        comments.add(ForumComment.fromJson(data));
      }
      
      return comments;
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      return [];
    }
  }

  // Get replies for a post (alias for getComments)
  Future<List<ForumComment>> getPostReplies(String postId) async {
    return getComments(postId);
  }

  // Add comment
  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('forum_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
    });
  }

  // Upvote post
  Future<void> upvotePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Check if user already voted
      final existingVote = await _client
          .from('forum_votes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existingVote != null) {
        // Remove vote
        await _client
            .from('forum_votes')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
        
        // Decrement upvote count
        await _client.rpc('decrement_post_upvotes', params: {'post_id_param': postId});
      } else {
        // Add vote
        await _client.from('forum_votes').insert({
          'user_id': userId,
          'post_id': postId,
          'vote_type': 1,
        });
        
        // Increment upvote count
        await _client.rpc('increment_post_upvotes', params: {'post_id_param': postId});
      }
    } catch (e) {
      debugPrint('Error upvoting post: $e');
      // Fallback: try direct update
      try {
        final post = await getPostById(postId);
        if (post != null) {
          await _client
              .from('forum_posts')
              .update({'upvotes': post.upvotes + 1})
              .eq('id', postId);
        }
      } catch (e2) {
        debugPrint('Fallback upvote also failed: $e2');
      }
    }
  }

  // Check if user has upvoted a post
  Future<bool> hasUserUpvoted(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final vote = await _client
          .from('forum_votes')
          .select()
          .eq('user_id', userId)
          .eq('post_id', postId)
          .maybeSingle();
      
      return vote != null;
    } catch (e) {
      debugPrint('Error checking upvote status: $e');
      return false;
    }
  }
}
