import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/forum_post.dart';
import '../../../data/repositories/forum_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/skeleton_loader.dart';

final enhancedForumPostDetailProvider = FutureProvider.family<ForumPost?, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.getPostById(postId);
});

final enhancedForumRepliesProvider = FutureProvider.family<List<ForumComment>, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.getPostReplies(postId);
});

final replyingToProvider = StateProvider<ForumComment?>((ref) => null);

final hasUserUpvotedPostProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.hasUserUpvoted(postId);
});

class EnhancedForumPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const EnhancedForumPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<EnhancedForumPostDetailScreen> createState() => _EnhancedForumPostDetailScreenState();
}

class _EnhancedForumPostDetailScreenState extends ConsumerState<EnhancedForumPostDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _replyFocusNode = FocusNode();
  bool _showFAB = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_showFAB) {
      setState(() => _showFAB = true);
    } else if (_scrollController.offset <= 100 && _showFAB) {
      setState(() => _showFAB = false);
    }
  }

  Future<void> _upvotePost() async {
    try {
      final repo = ForumRepository();
      await repo.upvotePost(widget.postId);
      
      // Refresh both the post data and upvote status
      ref.invalidate(enhancedForumPostDetailProvider(widget.postId));
      ref.invalidate(hasUserUpvotedPostProvider(widget.postId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote updated!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _replyToComment(ForumComment comment) {
    ref.read(replyingToProvider.notifier).state = comment;
    _replyController.clear();
    _replyFocusNode.requestFocus();
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to reply')),
      );
      return;
    }

    final replyingTo = ref.read(replyingToProvider);

    try {
      await SupabaseConfig.client.from('forum_replies').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'content': _replyController.text.trim(),
        'parent_reply_id': replyingTo?.id,
      });

      _replyController.clear();
      ref.read(replyingToProvider.notifier).state = null;
      ref.invalidate(enhancedForumRepliesProvider(widget.postId));
      ref.invalidate(enhancedForumPostDetailProvider(widget.postId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    }
  }

  Future<void> _deleteReply(String replyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseConfig.client.from('forum_replies').delete().eq('id', replyId);
      ref.invalidate(enhancedForumRepliesProvider(widget.postId));
      ref.invalidate(enhancedForumPostDetailProvider(widget.postId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Widget> _buildThreadedComments(List<ForumComment> allComments, String? currentUserId) {
    final topLevel = allComments.where((c) => c.parentId == null).toList();
    
    List<Widget> widgets = [];
    for (var comment in topLevel) {
      widgets.add(_CommentCard(
        comment: comment,
        currentUserId: currentUserId,
        onReply: () => _replyToComment(comment),
        onDelete: () => _deleteReply(comment.id),
        depth: 0,
      ));
      
      widgets.addAll(_buildNestedReplies(comment, allComments, 1, currentUserId));
    }
    return widgets;
  }

  List<Widget> _buildNestedReplies(ForumComment parent, List<ForumComment> all, int depth, String? currentUserId) {
    final children = all.where((c) => c.parentId == parent.id).toList();
    List<Widget> widgets = [];
    
    for (var child in children) {
      widgets.add(_CommentCard(
        comment: child,
        currentUserId: currentUserId,
        onReply: () => _replyToComment(child),
        onDelete: () => _deleteReply(child.id),
        depth: depth,
      ));
      if (depth < 5) { // Allow up to 5 levels of nesting
        widgets.addAll(_buildNestedReplies(child, all, depth + 1, currentUserId));
      }
    }
    return widgets;
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'programming': return ModernTheme.primaryOrange;
      case 'database': return const Color(0xFF8B5CF6);
      case 'networking': return const Color(0xFF10B981);
      case 'projects': return const Color(0xFF3B82F6);
      case 'career': return const Color(0xFFEC4899);
      case 'exams': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  Widget _buildAvatar(String? avatarUrl, String name, double size) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: size / 2,
          backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: ModernTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: size / 2.5,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: ModernTheme.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: size / 2.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(enhancedForumPostDetailProvider(widget.postId));
    final repliesAsync = ref.watch(enhancedForumRepliesProvider(widget.postId));
    final hasUpvoted = ref.watch(hasUserUpvotedPostProvider(widget.postId));
    final currentUser = SupabaseConfig.client.auth.currentUser;

    return Scaffold(
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Simple AppBar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    elevation: 1,
                    leading: IconButton(
                      icon: const Icon(Iconsax.arrow_left),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: const Text('Discussion'),
                  ),

                  // Post Content
                  SliverToBoxAdapter(
                    child: _PostContent(
                      post: post,
                      buildAvatar: _buildAvatar,
                      formatTimeAgo: _formatTimeAgo,
                      categoryColor: _getCategoryColor(post.category),
                    ),
                  ),

                  // Divider
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Divider(height: 1),
                    ),
                  ),

                  // Comments Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Iconsax.message_text, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${post.replyCount} Comments',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Comments List
                  repliesAsync.when(
                    data: (replies) {
                      if (replies.isEmpty) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                children: [
                                  Icon(Iconsax.message_text, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text('No comments yet', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(height: 8),
                                  const Text('Be the first to comment!', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final threadedComments = _buildThreadedComments(replies, currentUser?.id);
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => threadedComments[index],
                          childCount: threadedComments.length,
                        ),
                      );
                    },
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            CommentSkeleton(),
                            CommentSkeleton(),
                            CommentSkeleton(depth: 1),
                            CommentSkeleton(),
                            CommentSkeleton(depth: 1),
                            CommentSkeleton(depth: 2),
                          ],
                        ),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: Center(child: Text('Error loading comments: $error')),
                    ),
                  ),

                  // Bottom padding for reply bar
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),

              // Floating Upvote Button
              Positioned(
                right: 20,
                bottom: 100,
                child: AnimatedScale(
                  scale: _showFAB ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: hasUpvoted.when(
                    data: (upvoted) => FloatingActionButton(
                      heroTag: 'upvote',
                      onPressed: _upvotePost,
                      backgroundColor: upvoted ? Colors.green : ModernTheme.primaryOrange,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            upvoted ? Iconsax.arrow_up_15 : Iconsax.arrow_up,
                            color: Colors.white,
                          ),
                          Text(
                            '${post.upvotes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const FloatingActionButton(
                      heroTag: 'upvote',
                      onPressed: null,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    error: (error, stack) => FloatingActionButton(
                      heroTag: 'upvote',
                      onPressed: _upvotePost,
                      child: const Icon(Iconsax.arrow_up),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ForumPostSkeleton(),
            ],
          ),
        )),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.info_circle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${error.toString()}'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _ReplyInputBar(
        controller: _replyController,
        focusNode: _replyFocusNode,
        onSubmit: _submitReply,
        replyingToProvider: replyingToProvider,
        buildAvatar: _buildAvatar,
      ),
    );
  }
}

// Post Content Widget
class _PostContent extends StatelessWidget {
  final ForumPost post;
  final Widget Function(String?, String, double) buildAvatar;
  final String Function(DateTime) formatTimeAgo;
  final Color categoryColor;

  const _PostContent({
    required this.post,
    required this.buildAvatar,
    required this.formatTimeAgo,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                buildAvatar(post.userAvatar, post.authorName, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title - Smaller and cleaner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              post.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
            ),
          ),

          const SizedBox(height: 12),

          // Category Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                post.category.toUpperCase(),
                style: TextStyle(
                  color: categoryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatChip(
                  icon: Iconsax.eye,
                  value: post.views.toString(),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Iconsax.arrow_up,
                  value: post.upvotes.toString(),
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Iconsax.message,
                  value: post.replyCount.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: MarkdownBody(
              data: post.content,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
                h1: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                h2: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                h3: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                code: TextStyle(
                  backgroundColor: Colors.grey[900],
                  color: Colors.greenAccent,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                codeblockDecoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                a: const TextStyle(color: ModernTheme.primaryOrange),
              ),
            ),
          ),

          // Tags
          if (post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: post.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Stat Chip Widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Comment Card Widget - Reddit Style Threading
class _CommentCard extends ConsumerWidget {
  final ForumComment comment;
  final String? currentUserId;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final int depth;

  const _CommentCard({
    required this.comment,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
    required this.depth,
  });

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }

  Widget _buildAvatar(String? avatarUrl, String name, double size, BuildContext context) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: size / 2,
          backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: TextStyle(
              color: ModernTheme.primaryOrange,
              fontWeight: FontWeight.bold,
              fontSize: size / 2.5,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: ModernTheme.primaryOrange,
          fontWeight: FontWeight.bold,
          fontSize: size / 2.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leftPadding = 20.0 + (depth * 16.0); // Reduced indent for cleaner look
    final isOwnComment = currentUserId != null && comment.userId == currentUserId;
    
    return Container(
      margin: EdgeInsets.only(left: leftPadding, right: 20, bottom: 0),
      decoration: BoxDecoration(
        border: depth > 0 
            ? Border(
                left: BorderSide(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                  width: 2,
                ),
              )
            : null,
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 0, top: 12, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info Row
            Row(
              children: [
                _buildAvatar(comment.userAvatar, comment.authorName, 28, context),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        comment.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${_formatTimeAgo(comment.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.upvotes > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.arrow_up, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${comment.upvotes}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: MarkdownBody(
                data: comment.content,
                styleSheet: MarkdownStyleSheet(
                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontSize: 14,
                      ),
                  code: TextStyle(
                    backgroundColor: Colors.grey[200],
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  a: const TextStyle(color: ModernTheme.primaryOrange),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Action Buttons Row
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Row(
                children: [
                  // Reply Button
                  InkWell(
                    onTap: onReply,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.message,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Delete Button (only for own comments)
                  if (isOwnComment) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Iconsax.trash,
                              size: 14,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Delete',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reply Input Bar Widget
class _ReplyInputBar extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;
  final StateProvider<ForumComment?> replyingToProvider;
  final Widget Function(String?, String, double) buildAvatar;

  const _ReplyInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.replyingToProvider,
    required this.buildAvatar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replyingTo = ref.watch(replyingToProvider);
    final currentUser = SupabaseConfig.client.auth.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Replying To Banner
              if (replyingTo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: ModernTheme.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Replying to ${replyingTo.authorName}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: ModernTheme.primaryOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Iconsax.close_circle, size: 16),
                        onPressed: () {
                          ref.read(replyingToProvider.notifier).state = null;
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        color: ModernTheme.primaryOrange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Input Row
              Row(
                children: [
                  // User Avatar
                  if (currentUser != null)
                    buildAvatar(null, currentUser.email ?? 'U', 32),
                  const SizedBox(width: 12),

                  // Text Field
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: replyingTo != null 
                            ? 'Write a reply...'
                            : 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: ModernTheme.primaryOrange,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSubmit(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send Button
                  Container(
                    decoration: const BoxDecoration(
                      gradient: ModernTheme.orangeGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Iconsax.send_1, color: Colors.white),
                      onPressed: onSubmit,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
