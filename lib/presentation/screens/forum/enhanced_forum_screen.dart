import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/forum_post.dart';
import '../../../data/repositories/forum_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';

// Provider for all forum posts
final allForumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  final repo = ForumRepository();
  return await repo.getPosts();
});

// State providers for filters
final forumSearchQueryProvider = StateProvider<String>((ref) => '');
final forumSelectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Filtered posts provider
final filteredForumPostsProvider = Provider<AsyncValue<List<ForumPost>>>((ref) {
  final postsAsync = ref.watch(allForumPostsProvider);
  final searchQuery = ref.watch(forumSearchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(forumSelectedCategoryProvider);

  return postsAsync.whenData((posts) {
    return posts.where((post) {
      final matchesSearch = post.title.toLowerCase().contains(searchQuery) ||
          post.content.toLowerCase().contains(searchQuery) ||
          post.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      final matchesCategory =
          selectedCategory == 'all' || post.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  });
});

class EnhancedForumScreen extends ConsumerWidget {
  const EnhancedForumScreen({super.key});

  Future<void> _deletePost(BuildContext context, WidgetRef ref, String postId) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This will also delete all replies.'),
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
      await SupabaseConfig.client.from('forum_posts').delete().eq('id', postId);

      ref.invalidate(allForumPostsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredPostsAsync = ref.watch(filteredForumPostsProvider);
    final searchQuery = ref.watch(forumSearchQueryProvider);
    final selectedCategory = ref.watch(forumSelectedCategoryProvider);
    final currentUser = SupabaseConfig.client.auth.currentUser;

    final categories = [
      'all',
      'general',
      'programming',
      'database',
      'networking',
      'projects',
      'career',
      'exams'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discussion Forum', style: TextStyle(fontSize: 20)),
            Text(
              'Ask questions and share knowledge',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => ref.read(forumSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search discussions...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: () => ref.read(forumSearchQueryProvider.notifier).state = '',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),

          // Category Filter Pills
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, error) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return FilterChip(
                  label: Text(category == 'all' ? 'All Topics' : _formatCategory(category)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(forumSelectedCategoryProvider.notifier).state = category;
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: ModernTheme.primaryOrange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? ModernTheme.primaryOrange
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Posts List
          Expanded(
            child: filteredPostsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.message_text,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No discussions found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try adjusting your search'
                              : 'Be the first to start a discussion!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        if (searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.push('/forum/create'),
                            icon: const Icon(Iconsax.add),
                            label: const Text('Start Discussion'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allForumPostsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (context, error) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ForumPostCard(
                        post: posts[index],
                        currentUserId: currentUser?.id,
                        onDelete: () => _deletePost(context, ref, posts[index].id),
                      );
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                separatorBuilder: (context, error) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.danger,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading discussions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ref.invalidate(allForumPostsProvider),
                      icon: const Icon(Iconsax.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/forum/create'),
        icon: const Icon(Iconsax.add),
        label: const Text('New Discussion'),
        backgroundColor: ModernTheme.primaryOrange,
      ),
    );
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }
}

class _ForumPostCard extends StatelessWidget {
  final ForumPost post;
  final String? currentUserId;
  final VoidCallback onDelete;

  const _ForumPostCard({
    required this.post,
    this.currentUserId,
    required this.onDelete,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return ModernTheme.primaryOrange;
      case 'database':
        return const Color(0xFF8B5CF6);
      case 'networking':
        return const Color(0xFF10B981);
      case 'projects':
        return const Color(0xFF3B82F6);
      case 'career':
        return const Color(0xFFEC4899);
      case 'exams':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/forum/${post.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badges
            Row(
              children: [
                if (post.isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.location, size: 12, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Pinned',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (post.isLocked) ...[
                  if (post.isPinned) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Iconsax.lock, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                if (currentUserId != null && post.userId == currentUserId)
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 18),
                    color: Colors.red,
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Content preview
            Text(
              post.content.replaceAll(RegExp(r'[#*`]'), ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(post.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    post.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(post.category),
                    ),
                  ),
                ),
                ...post.tags.take(2).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                // Author
                CircleAvatar(
                  radius: 12,
                  backgroundColor: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                  child: Text(
                    post.authorName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.primaryOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    post.authorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),

                // Stats
                Row(
                  children: [
                    Icon(Iconsax.arrow_up, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${post.upvotes}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Icon(Iconsax.message, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${post.replyCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Icon(Iconsax.eye, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${post.views}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Time
                Text(
                  _formatTimeAgo(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
