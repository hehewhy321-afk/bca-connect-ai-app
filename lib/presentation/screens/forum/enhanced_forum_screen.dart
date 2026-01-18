import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/forum_post.dart';
import '../../../data/repositories/forum_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../widgets/skeleton_loader.dart';

// Provider for all forum posts
final allForumPostsProvider = FutureProvider<List<ForumPost>>((ref) async {
  final repo = ForumRepository();
  return await repo.getPosts();
});

// Provider to check if user has upvoted a specific post
final hasUserUpvotedForumPostProvider = FutureProvider.family<bool, String>((ref, postId) async {
  final repo = ForumRepository();
  return await repo.hasUserUpvoted(postId);
});

// State providers for filters
final forumSearchQueryProvider = StateProvider<String>((ref) => '');
final forumSelectedCategoryProvider = StateProvider<String>((ref) => 'all');
final forumSortByProvider = StateProvider<String>((ref) => 'latest'); // latest, views, comments

// Filtered posts provider
final filteredForumPostsProvider = Provider<AsyncValue<List<ForumPost>>>((ref) {
  final postsAsync = ref.watch(allForumPostsProvider);
  final searchQuery = ref.watch(forumSearchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(forumSelectedCategoryProvider);
  final sortBy = ref.watch(forumSortByProvider);

  return postsAsync.whenData((posts) {
    var filtered = posts.where((post) {
      final matchesSearch = post.title.toLowerCase().contains(searchQuery) ||
          post.content.toLowerCase().contains(searchQuery) ||
          post.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      final matchesCategory =
          selectedCategory == 'all' || post.category.toLowerCase() == selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    // Apply sorting
    switch (sortBy) {
      case 'views':
        filtered.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'comments':
        filtered.sort((a, b) => b.replyCount.compareTo(a.replyCount));
        break;
      case 'latest':
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
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
    final sortBy = ref.watch(forumSortByProvider);
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

    // Check if any filter is active
    final hasActiveFilters = selectedCategory != 'all' || sortBy != 'latest';

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
          // Search Bar with Filter Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 12),
                // Filter Button
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: hasActiveFilters
                            ? const LinearGradient(
                                colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                              )
                            : null,
                        color: hasActiveFilters ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Iconsax.filter,
                          color: hasActiveFilters ? Colors.white : Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => _showFilterModal(context, ref),
                      ),
                    ),
                    if (hasActiveFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                    side: BorderSide(
                      color: isSelected
                          ? ModernTheme.primaryOrange
                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
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
                itemBuilder: (context, index) => const ForumPostSkeleton(),
              ),
              error: (error, stack) {
                // Check if it's a network error
                final isNetworkError = error.toString().contains('No internet connection') ||
                    error.toString().contains('SocketException') ||
                    error.toString().contains('Failed host lookup');

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNetworkError ? Iconsax.wifi_square : Iconsax.danger,
                        size: 64,
                        color: isNetworkError
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNetworkError ? 'No Internet Connection' : 'Error loading discussions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          isNetworkError
                              ? 'Please check your internet connection and try again'
                              : 'Something went wrong. Please try again',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(allForumPostsProvider),
                        icon: const Icon(Iconsax.refresh),
                        label: const Text('Retry'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ModernTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'forum_create_fab',
        onPressed: () => context.push('/forum/create'),
        icon: const Icon(Iconsax.add),
        label: const Text('New Dission'),
        backgroundColor: ModernTheme.primaryOrange,
      ),
    );
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  void _showFilterModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Use local state variables
        String localCategory = ref.read(forumSelectedCategoryProvider);
        String localSortBy = ref.read(forumSortByProvider);
        
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Iconsax.filter, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Filter & Sort',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Iconsax.close_circle),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sort By Section
                      Text(
                        'Sort By',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _FilterOption(
                        icon: Iconsax.clock,
                        title: 'Latest',
                        subtitle: 'Most recent posts first',
                        isSelected: localSortBy == 'latest',
                        onTap: () {
                          setState(() {
                            localSortBy = 'latest';
                          });
                          ref.read(forumSortByProvider.notifier).state = 'latest';
                        },
                      ),
                      const SizedBox(height: 8),
                      _FilterOption(
                        icon: Iconsax.eye,
                        title: 'Most Viewed',
                        subtitle: 'Posts with most views',
                        isSelected: localSortBy == 'views',
                        onTap: () {
                          setState(() {
                            localSortBy = 'views';
                          });
                          ref.read(forumSortByProvider.notifier).state = 'views';
                        },
                      ),
                      const SizedBox(height: 8),
                      _FilterOption(
                        icon: Iconsax.message_text,
                        title: 'Most Discussed',
                        subtitle: 'Posts with most comments',
                        isSelected: localSortBy == 'comments',
                        onTap: () {
                          setState(() {
                            localSortBy = 'comments';
                          });
                          ref.read(forumSortByProvider.notifier).state = 'comments';
                        },
                      ),

                      const SizedBox(height: 24),

                      // Category Section
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'all',
                          'general',
                          'programming',
                          'database',
                          'networking',
                          'projects',
                          'career',
                          'exams'
                        ].map((category) {
                          final isSelected = localCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                localCategory = category;
                              });
                              ref.read(forumSelectedCategoryProvider.notifier).state = category;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                      )
                                    : null,
                                color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                category == 'all' ? 'All Topics' : _formatCategory(category),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  localCategory = 'all';
                                  localSortBy = 'latest';
                                });
                                ref.read(forumSelectedCategoryProvider.notifier).state = 'all';
                                ref.read(forumSortByProvider.notifier).state = 'latest';
                              },
                              icon: const Icon(Iconsax.refresh),
                              label: const Text('Clear Filters'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Apply',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    final categoryColor = _getCategoryColor(post.category);
    
    return InkWell(
      onTap: () => context.push('/forum/${post.id}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and badges
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // User Avatar with image support
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: categoryColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: categoryColor.withValues(alpha: 0.1),
                      backgroundImage: post.userAvatar != null && post.userAvatar!.isNotEmpty
                          ? NetworkImage(post.userAvatar!)
                          : null,
                      child: post.userAvatar == null || post.userAvatar!.isEmpty
                          ? Text(
                              post.authorName.isNotEmpty 
                                  ? post.authorName.substring(0, 1).toUpperCase() 
                                  : 'U',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // User info and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isPinned) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.location5,
                                size: 14,
                                color: Colors.amber[700],
                              ),
                            ],
                            if (post.isLocked) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Iconsax.lock5,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimeAgo(post.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Delete button for own posts
                  if (currentUserId != null && post.userId == currentUserId)
                    IconButton(
                      icon: const Icon(Iconsax.trash, size: 20),
                      color: Colors.red,
                      onPressed: onDelete,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                ],
              ),
            ),

            // Category badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0.2),
                      categoryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: categoryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(post.category),
                      size: 14,
                      color: categoryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      post.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: categoryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.3,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 8),

            // Content preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content.replaceAll(RegExp(r'[#*`\n]'), ' ').trim(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Tags
            if (post.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: post.tags.take(3).map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.hashtag,
                              size: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Divider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),

            // Footer with stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Upvotes - Interactive
                  _StatItem(
                    icon: Iconsax.arrow_up_1,
                    value: post.upvotes,
                    color: Colors.green,
                    isUpvote: true,
                    postId: post.id,
                  ),
                  const SizedBox(width: 12),
                  
                  // Comments
                  _StatItem(
                    icon: Iconsax.message_text_1,
                    value: post.replyCount,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  
                  // Views
                  _StatItem(
                    icon: Iconsax.eye,
                    value: post.views,
                    color: Colors.orange,
                  ),
                  
                  const Spacer(),
                  
                  // Read more indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Read',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ModernTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Iconsax.arrow_right_3,
                          size: 16,
                          color: ModernTheme.primaryOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'programming':
        return Iconsax.code_1;
      case 'database':
        return Iconsax.data;
      case 'networking':
        return Iconsax.global;
      case 'projects':
        return Iconsax.folder_2;
      case 'career':
        return Iconsax.briefcase;
      case 'exams':
        return Iconsax.book_1;
      default:
        return Iconsax.message_text_1;
    }
  }
}

// Stat item widget for footer - Improved UI with compact spacing
class _StatItem extends ConsumerWidget {
  final IconData icon;
  final int value;
  final Color color;
  final bool isUpvote;
  final String? postId;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.color,
    this.isUpvote = false,
    this.postId,
  });

  Future<void> _handleUpvote(BuildContext context, WidgetRef ref) async {
    if (postId == null) return;
    
    try {
      final repo = ForumRepository();
      await repo.upvotePost(postId!);
      
      // Refresh the posts list and upvote status
      ref.invalidate(allForumPostsProvider);
      ref.invalidate(hasUserUpvotedForumPostProvider(postId!));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote updated!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update vote: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isUpvote && postId != null) {
      final hasUpvoted = ref.watch(hasUserUpvotedForumPostProvider(postId!));
      
      return hasUpvoted.when(
        data: (upvoted) => InkWell(
          onTap: () => _handleUpvote(context, ref),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: upvoted ? Colors.green : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  upvoted ? Iconsax.arrow_up_15 : icon,
                  size: 18,
                  color: upvoted ? Colors.white : color,
                ),
                const SizedBox(width: 4),
                Text(
                  value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: upvoted ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
        loading: () => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Non-interactive stat item
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Filter Option Widget for Modal
class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [ModernTheme.primaryOrange, Color(0xFFFF9A3C)],
                  )
                : null,
            color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : ModernTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : ModernTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white70
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Iconsax.tick_circle5,
                  color: Colors.white,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
