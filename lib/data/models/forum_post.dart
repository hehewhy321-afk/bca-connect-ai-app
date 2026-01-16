class ForumPost {
  final String id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final int views;
  final int upvotes;
  final int downvotes;
  final int commentsCount;
  final bool isPinned;
  final bool isLocked;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed properties
  String get authorName => userName ?? 'Anonymous';
  int get replyCount => commentsCount;

  ForumPost({
    required this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.title,
    required this.content,
    required this.category,
    this.tags = const [],
    this.views = 0,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentsCount = 0,
    this.isPinned = false,
    this.isLocked = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      views: json['views'] as int? ?? 0,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'views': views,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'comments_count': commentsCount,
      'is_pinned': isPinned,
      'is_locked': isLocked,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ForumComment {
  final String id;
  final String postId;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String content;
  final String? parentId;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Computed property
  String get authorName => userName ?? 'Anonymous';

  ForumComment({
    required this.id,
    required this.postId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.content,
    this.parentId,
    this.upvotes = 0,
    this.downvotes = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      content: json['content'] as String,
      parentId: json['parent_reply_id'] as String?,
      upvotes: json['upvotes'] as int? ?? 0,
      downvotes: json['downvotes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'parent_reply_id': parentId,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
