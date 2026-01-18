import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/event_provider.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/cached_image.dart';

// State providers for filters
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String>((ref) => 'all');

// Filtered events provider - uses upcomingEventsProvider (same as home screen)
final filteredEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(upcomingEventsProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final selectedCategory = ref.watch(selectedCategoryProvider);

  return eventsAsync.whenData((events) {
    return events.where((event) {
      // Search filter
      final matchesSearch = event.title.toLowerCase().contains(searchQuery) ||
          (event.description?.toLowerCase().contains(searchQuery) ?? false);
      
      // Category filter
      final matchesCategory =
          selectedCategory == 'all' || event.category.toLowerCase() == selectedCategory.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();
  });
});

class EnhancedEventsScreen extends ConsumerWidget {
  const EnhancedEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEventsAsync = ref.watch(filteredEventsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    final categories = ['all', 'Workshop', 'Seminar', 'Competition', 'Social'];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: TextStyle(fontSize: 20)),
            Text(
              'Discover and register for events',
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
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
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
                  label: Text(category == 'all' ? 'All' : category),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(selectedCategoryProvider.notifier).state = category;
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

          // Events List
          Expanded(
            child: filteredEventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.calendar_remove,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filter',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(upcomingEventsProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _EventCard(event: events[index]);
                    },
                  ),
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) => const EventCardSkeleton(),
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
                        isNetworkError ? 'No Internet Connection' : 'Error loading events',
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
                        onPressed: () => ref.invalidate(upcomingEventsProvider),
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
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workshop':
        return ModernTheme.primaryOrange;
      case 'seminar':
        return const Color(0xFF8B5CF6);
      case 'competition':
        return const Color(0xFFEC4899);
      case 'social':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFF3B82F6);
      case 'ongoing':
        return const Color(0xFF10B981);
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: event.imageUrl != null
                      ? CachedImage(
                          imageUrl: event.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          errorWidget: _buildPlaceholderImage(context),
                        )
                      : _buildPlaceholderImage(context),
                ),
                // Gradient overlay for better badge visibility
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryColor(event.category).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getStatusColor(event.status).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          event.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Featured Badge
                if (event.isFeatured)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Iconsax.star5, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Date & Time Info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Iconsax.calendar_1,
                              size: 14,
                              color: ModernTheme.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy • hh:mm a').format(event.startDate),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (event.endDate != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Iconsax.calendar_tick,
                                size: 14,
                                color: ModernTheme.primaryOrange,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM dd, yyyy • hh:mm a').format(event.endDate!),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Location
                  if (event.location != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 14,
                            color: ModernTheme.primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Additional Info Row
                  Row(
                    children: [
                      // Team Type
                      if (event.teamType == 'team')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.people, size: 11, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                'Team ${event.teamSizeMin}-${event.teamSizeMax}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      // Registration Fee
                      if (event.registrationFee != null && event.registrationFee! > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: ModernTheme.orangeGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.wallet, size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getCategoryColor(event.category), _getCategoryColor(event.category).withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.calendar_1,
          size: 64,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
