import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/theme/modern_theme.dart';

// Provider for user's registered events with full event details
final myEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = EventRepository();
  final registrations = await repo.getUserRegistrations();
  
  // Extract events from registrations
  final events = registrations
      .where((r) => r['events'] != null)
      .map((r) => Event.fromJson(r['events'] as Map<String, dynamic>))
      .toList();
  
  // Sort by start date
  events.sort((a, b) => a.startDate.compareTo(b.startDate));
  
  return events;
});

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Events', style: TextStyle(fontSize: 20)),
            Text(
              'Events you have registered for',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: myEventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.calendar_remove,
                      size: 64,
                      color: ModernTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Registered Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'You haven\'t registered for any events yet. Browse available events and register now!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.push('/events'),
                    icon: const Icon(Iconsax.calendar_search),
                    label: const Text('Browse Events'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ModernTheme.primaryOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate events by status
          final upcomingEvents = events.where((e) => 
            e.status.toLowerCase() == 'upcoming' || e.status.toLowerCase() == 'ongoing'
          ).toList();
          
          final completedEvents = events.where((e) => 
            e.status.toLowerCase() == 'completed'
          ).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myEventsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Upcoming Events Section
                if (upcomingEvents.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: ModernTheme.orangeGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.calendar_tick, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Upcoming Events',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ModernTheme.primaryOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${upcomingEvents.length}',
                          style: const TextStyle(
                            color: ModernTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...upcomingEvents.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MyEventCard(event: event),
                      )),
                  const SizedBox(height: 24),
                ],

                // Completed Events Section
                if (completedEvents.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Iconsax.tick_circle, color: Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Completed Events',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${completedEvents.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...completedEvents.map((event) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MyEventCard(event: event, isCompleted: true),
                      )),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.danger, size: 64, color: Colors.red),
              ),
              const SizedBox(height: 24),
              Text(
                'Error loading events',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
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
                onPressed: () => ref.invalidate(myEventsProvider),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: ModernTheme.primaryOrange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyEventCard extends StatelessWidget {
  final Event event;
  final bool isCompleted;

  const _MyEventCard({
    required this.event,
    this.isCompleted = false,
  });

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

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM dd, hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/events/${event.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isCompleted 
              ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isCompleted
                ? Colors.grey.withValues(alpha: 0.2)
                : ModernTheme.primaryOrange.withValues(alpha: 0.3),
            width: isCompleted ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isCompleted ? null : [
            BoxShadow(
              color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
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
                      ? ColorFiltered(
                          colorFilter: isCompleted
                              ? ColorFilter.mode(
                                  Colors.grey.withValues(alpha: 0.5),
                                  BlendMode.saturation,
                                )
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                ),
                          child: Image.network(
                            event.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(context),
                          ),
                        )
                      : _buildPlaceholderImage(context),
                ),
                // Registered Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: isCompleted ? null : ModernTheme.orangeGradient,
                      color: isCompleted ? Colors.grey : null,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (isCompleted ? Colors.grey : ModernTheme.primaryOrange)
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.tick_circle5, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          isCompleted ? 'Completed' : 'Registered',
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
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event.category).withValues(alpha: isCompleted ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCategoryColor(event.category).withValues(alpha: isCompleted ? 0.3 : 0.5),
                      ),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        color: isCompleted ? Colors.grey : _getCategoryColor(event.category),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCompleted 
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                              : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 16,
                        color: isCompleted ? Colors.grey : ModernTheme.primaryOrange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDate(event.startDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                color: isCompleted 
                                    ? Colors.grey
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (event.location != null)
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 16,
                          color: isCompleted ? Colors.grey : ModernTheme.primaryOrange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                  color: isCompleted 
                                      ? Colors.grey
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.grey, Colors.grey.withValues(alpha: 0.7)]
              : [_getCategoryColor(event.category), _getCategoryColor(event.category).withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Iconsax.calendar_1,
          size: 48,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
