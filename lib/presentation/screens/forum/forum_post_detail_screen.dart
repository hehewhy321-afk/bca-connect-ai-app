import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/forum_post.dart';
import '../../../data/repositories/forum_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';

final forumPostDetailProvider = FutureProvider.family<ForumPost?, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.getPostById(postId);
});

final forumRepliesProvider = FutureProvider.family<List<ForumComment>, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.getPostReplies(postId);
});

// Provider to track user's vote on a post
final postVoteProvider = FutureProvider.family<int, String>((ref, postId) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return 0;

  try {
    final response = await SupabaseConfig.client
        .from('forum_votes')
        .select('vote_type')
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return 0;
    return response['vote_type'] as int;
  } catch (e) {
    return 0;
  }
});

// Provider to track user's vote on a reply
final replyVoteProvider = FutureProvider.family<int, String>((ref, replyId) async {
  final user = SupabaseConfig.client.auth.currentUser;
  if (user == null) return 0;

  try {
    final response = await SupabaseConfig.client
        .from('forum_votes')
        .select('vote_type')
        .eq('reply_id', replyId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return 0;
    return response['vote_type'] as int;
  } catch (e) {
    return 0;
  }
});

class ForumPostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const ForumPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends ConsumerState<ForumPostDetailScreen> {
  final _replyController = TextEditingController();
  String? _replyingToId;
  String? _replyingToName;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleVote(String postId, int voteType) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to vote')),
      );
      return;
    }

    try {
      // Check if user already voted
      final existingVote = await SupabaseConfig.client
          .from('forum_votes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingVote != null) {
        final currentVote = existingVote['vote_type'] as int;
        
        if (currentVote == voteType) {
          // Remove vote
          await SupabaseConfig.client
              .from('forum_votes')
              .delete()
              .eq('id', existingVote['id']);
          
          // Update post count
          await SupabaseConfig.client.rpc(
            'update_post_votes',
            params: {'post_id': postId, 'vote_change': -voteType},
          );
        } else {
          // Change vote
          await SupabaseConfig.client
              .from('forum_votes')
              .update({'vote_type': voteType})
              .eq('id', existingVote['id']);
          
          // Update post count (remove old, add new)
          await SupabaseConfig.client.rpc(
            'update_post_votes',
            params: {'post_id': postId, 'vote_change': voteType - currentVote},
          );
        }
      } else {
        // New vote
        await SupabaseConfig.client.from('forum_votes').insert({
          'post_id': postId,
          'user_id': user.id,
          'vote_type': voteType,
        });
        
        // Update post count
        await SupabaseConfig.client.rpc(
          'update_post_votes',
          params: {'post_id': postId, 'vote_change': voteType},
        );
      }

      // Refresh data
      ref.invalidate(forumPostDetailProvider(postId));
      ref.invalidate(postVoteProvider(postId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote: $e')),
        );
      }
    }
  }

  Future<void> _handleReplyVote(String replyId, int voteType) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to vote')),
      );
      return;
    }

    try {
      final existingVote = await SupabaseConfig.client
          .from('forum_votes')
          .select()
          .eq('reply_id', replyId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingVote != null) {
        final currentVote = existingVote['vote_type'] as int;
        
        if (currentVote == voteType) {
          await SupabaseConfig.client
              .from('forum_votes')
              .delete()
              .eq('id', existingVote['id']);
          
          await SupabaseConfig.client.rpc(
            'update_reply_votes',
            params: {'reply_id': replyId, 'vote_change': -voteType},
          );
        } else {
          await SupabaseConfig.client
              .from('forum_votes')
              .update({'vote_type': voteType})
              .eq('id', existingVote['id']);
          
          await SupabaseConfig.client.rpc(
            'update_reply_votes',
            params: {'reply_id': replyId, 'vote_change': voteType - currentVote},
          );
        }
      } else {
        await SupabaseConfig.client.from('forum_votes').insert({
          'reply_id': replyId,
          'user_id': user.id,
          'vote_type': voteType,
        });
        
        await SupabaseConfig.client.rpc(
          'update_reply_votes',
          params: {'reply_id': replyId, 'vote_change': voteType},
        );
      }

      ref.invalidate(forumRepliesProvider(widget.postId));
      ref.invalidate(replyVoteProvider(replyId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote: $e')),
        );
      }
    }
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

    try {
      await SupabaseConfig.client.from('forum_replies').insert({
        'post_id': widget.postId,
        'user_id': user.id,
        'content': _replyController.text.trim(),
        'parent_reply_id': _replyingToId,
      });

      _replyController.clear();
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
      });

      ref.invalidate(forumRepliesProvider(widget.postId));
      ref.invalidate(forumPostDetailProvider(widget.postId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply posted successfully!')),
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

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(forumPostDetailProvider(widget.postId));
    final repliesAsync = ref.watch(forumRepliesProvider(widget.postId));
    final voteAsync = ref.watch(postVoteProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author Info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                                  child: Text(
                                    post.authorName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: ModernTheme.primaryOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                      Text(
                                        timeago.format(post.createdAt),
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
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              post.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Content
                            Text(
                              post.content,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                  ),
                            ),
                            const SizedBox(height: 16),

                            // Category & Tags
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _CategoryChip(label: post.category),
                                ...post.tags.map((tag) => _TagChip(label: tag)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Voting and Stats
                            Row(
                              children: [
                                // Upvote/Downvote
                                voteAsync.when(
                                  data: (userVote) => Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          userVote == 1 ? Iconsax.arrow_up_15 : Iconsax.arrow_up,
                                          color: userVote == 1 ? ModernTheme.primaryOrange : null,
                                        ),
                                        onPressed: () => _handleVote(post.id, 1),
                                      ),
                                      Text(
                                        '${post.upvotes - post.downvotes}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: userVote == 1
                                              ? ModernTheme.primaryOrange
                                              : userVote == -1
                                                  ? Colors.red
                                                  : null,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          userVote == -1 ? Iconsax.arrow_down_15 : Iconsax.arrow_down,
                                          color: userVote == -1 ? Colors.red : null,
                                        ),
                                        onPressed: () => _handleVote(post.id, -1),
                                      ),
                                    ],
                                  ),
                                  loading: () => const SizedBox(width: 120, child: Center(child: CircularProgressIndicator())),
                                  error: (error, stackTrace) => const SizedBox(width: 120),
                                ),
                                const Spacer(),
                                _StatItem(
                                  icon: Iconsax.eye,
                                  value: post.views.toString(),
                                  label: 'Views',
                                ),
                                const SizedBox(width: 24),
                                _StatItem(
                                  icon: Iconsax.message,
                                  value: post.replyCount.toString(),
                                  label: 'Replies',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Replies Section
                    Text(
                      'Replies (${post.replyCount})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    repliesAsync.when(
                      data: (replies) {
                        if (replies.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Iconsax.message_text,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No replies yet',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Be the first to reply!',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Build threaded replies
                        final topLevelReplies = replies.where((r) => r.parentId == null).toList();
                        
                        return Column(
                          children: topLevelReplies.map((reply) {
                            final childReplies = replies.where((r) => r.parentId == reply.id).toList();
                            return _ThreadedReplyCard(
                              reply: reply,
                              childReplies: childReplies,
                              onReply: (replyId, authorName) {
                                setState(() {
                                  _replyingToId = replyId;
                                  _replyingToName = authorName;
                                });
                              },
                              onVote: _handleReplyVote,
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error loading replies: $error'),
                      ),
                    ),
                  ],
                ),
              ),

              // Reply Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyingToName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Iconsax.arrow_right_3, size: 16, color: ModernTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Replying to $_replyingToName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: ModernTheme.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Iconsax.close_circle, size: 16),
                              onPressed: () {
                                setState(() {
                                  _replyingToId = null;
                                  _replyingToName = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyController,
                            decoration: InputDecoration(
                              hintText: _replyingToName != null 
                                  ? 'Write a reply to $_replyingToName...'
                                  : 'Write a reply...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: const BoxDecoration(
                            gradient: ModernTheme.orangeGradient,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Iconsax.send_1, color: Colors.white),
                            onPressed: _submitReply,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
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
    );
  }
}

class _ThreadedReplyCard extends ConsumerWidget {
  final ForumComment reply;
  final List<ForumComment> childReplies;
  final Function(String, String) onReply;
  final Function(String, int) onVote;

  const _ThreadedReplyCard({
    required this.reply,
    required this.childReplies,
    required this.onReply,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteAsync = ref.watch(replyVoteProvider(reply.id));

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: ModernTheme.accentOrange.withValues(alpha: 0.2),
                      child: Text(
                        reply.authorName[0].toUpperCase(),
                        style: const TextStyle(
                          color: ModernTheme.accentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reply.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            timeago.format(reply.createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  reply.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Voting
                    voteAsync.when(
                      data: (userVote) => Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              userVote == 1 ? Iconsax.arrow_up_15 : Iconsax.arrow_up,
                              size: 16,
                              color: userVote == 1 ? ModernTheme.primaryOrange : null,
                            ),
                            onPressed: () => onVote(reply.id, 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Text(
                            '${reply.upvotes - reply.downvotes}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: userVote == 1
                                  ? ModernTheme.primaryOrange
                                  : userVote == -1
                                      ? Colors.red
                                      : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              userVote == -1 ? Iconsax.arrow_down_15 : Iconsax.arrow_down,
                              size: 16,
                              color: userVote == -1 ? Colors.red : null,
                            ),
                            onPressed: () => onVote(reply.id, -1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(width: 80, height: 32, child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))),
                      error: (error, stackTrace) => const SizedBox(width: 80),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => onReply(reply.id, reply.authorName),
                      icon: const Icon(Iconsax.message, size: 14),
                      label: const Text('Reply', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Child replies (threaded)
        if (childReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 12),
            child: Column(
              children: childReplies.map((childReply) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Iconsax.arrow_right_3, size: 12, color: ModernTheme.primaryOrange),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                              child: Text(
                                childReply.authorName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: ModernTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    childReply.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    timeago.format(childReply.createdAt),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          childReply.content,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.4,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Consumer(
                          builder: (context, ref, child) {
                            final childVoteAsync = ref.watch(replyVoteProvider(childReply.id));
                            return childVoteAsync.when(
                              data: (userVote) => Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      userVote == 1 ? Iconsax.arrow_up_15 : Iconsax.arrow_up,
                                      size: 14,
                                      color: userVote == 1 ? ModernTheme.primaryOrange : null,
                                    ),
                                    onPressed: () => onVote(childReply.id, 1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  Text(
                                    '${childReply.upvotes - childReply.downvotes}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: userVote == 1
                                          ? ModernTheme.primaryOrange
                                          : userVote == -1
                                              ? Colors.red
                                              : null,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      userVote == -1 ? Iconsax.arrow_down_15 : Iconsax.arrow_down,
                                      size: 14,
                                      color: userVote == -1 ? Colors.red : null,
                                    ),
                                    onPressed: () => onVote(childReply.id, -1),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ],
                              ),
                              loading: () => const SizedBox(width: 70, height: 28, child: Center(child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)))),
                              error: (error, stackTrace) => const SizedBox(width: 70),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ModernTheme.primaryOrange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Text(
        '#$label',
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
