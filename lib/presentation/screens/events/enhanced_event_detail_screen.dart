import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/gradient_button.dart';

final eventDetailProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final repo = EventRepository();
  return await repo.getEventById(eventId);
});

class EnhancedEventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EnhancedEventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.info_circle, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Event not found'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      event.imageUrl != null
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                decoration: const BoxDecoration(
                                  gradient: ModernTheme.orangeGradient,
                                ),
                              ),
                            )
                          : Container(
                              decoration: const BoxDecoration(
                                gradient: ModernTheme.orangeGradient,
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Iconsax.share),
                    onPressed: () {},
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Badge(
                            label: event.category,
                            color: ModernTheme.primaryOrange,
                          ),
                          _Badge(
                            label: event.status,
                            color: _getStatusColor(event.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        event.description ?? 'No description available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Event Gallery
                      Row(
                        children: [
                          const Icon(Iconsax.gallery, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Event Gallery',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: event.galleryImages.isNotEmpty 
                              ? event.galleryImages.length 
                              : (event.imageUrl != null ? 3 : 0),
                          separatorBuilder: (context, error) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final imageUrl = event.galleryImages.isNotEmpty 
                                ? event.galleryImages[index]
                                : event.imageUrl;
                            
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: 150,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 150,
                                        height: 120,
                                        decoration: const BoxDecoration(
                                          gradient: ModernTheme.orangeGradient,
                                        ),
                                        child: const Icon(Iconsax.gallery, color: Colors.white, size: 32),
                                      ),
                                    )
                                  : Container(
                                      width: 150,
                                      height: 120,
                                      decoration: const BoxDecoration(
                                        gradient: ModernTheme.orangeGradient,
                                      ),
                                      child: const Icon(Iconsax.gallery, color: Colors.white, size: 32),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // About This Event
                      Row(
                        children: [
                          const Icon(Iconsax.info_circle, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'About This Event',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Iconsax.calendar,
                              label: 'Start Date',
                              value: DateFormat('EEEE, MMMM dd, yyyy').format(event.startDate),
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.clock,
                              label: 'Start Time',
                              value: DateFormat('hh:mm a').format(event.startDate),
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.calendar_tick,
                              label: 'End Date',
                              value: event.endDate != null 
                                  ? DateFormat('EEEE, MMMM dd, yyyy').format(event.endDate!)
                                  : 'TBA',
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.clock,
                              label: 'End Time',
                              value: event.endDate != null
                                  ? DateFormat('hh:mm a').format(event.endDate!)
                                  : 'TBA',
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.location,
                              label: 'Location',
                              value: event.location ?? 'TBA',
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.people,
                              label: 'Participation',
                              value: event.teamType == 'team' 
                                  ? 'Squad (${event.teamSizeMin}-${event.teamSizeMax} members)' 
                                  : 'Individual',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Event Schedule
                      Row(
                        children: [
                          const Icon(Iconsax.calendar_2, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Event Schedule',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ScheduleItem(
                        time: DateFormat('hh:mm a').format(event.startDate),
                        title: 'Event Begins',
                        description: 'Welcome and Introduction',
                        color: ModernTheme.primaryOrange,
                      ),
                      _ScheduleItem(
                        time: event.endDate != null
                            ? DateFormat('hh:mm a').format(event.endDate!)
                            : 'TBA',
                        title: 'Event Ends',
                        description: 'Closing remarks and networking',
                        color: Colors.grey,
                        isLast: true,
                      ),
                      const SizedBox(height: 24),

                      // Organized By
                      Row(
                        children: [
                          const Icon(Iconsax.user_octagon, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Organized By',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Iconsax.people, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Association Team',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Event Organizers',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Share Section
                      Row(
                        children: [
                          const Icon(Iconsax.share, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Share this event',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _ShareButton(icon: Iconsax.copy, onTap: () {}),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Iconsax.message, onTap: () {}),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Iconsax.send_2, onTap: () {}),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Iconsax.link, onTap: () {}),
                          const SizedBox(width: 12),
                          _ShareButton(icon: Iconsax.more, onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Additional Details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Iconsax.category,
                              label: 'Category',
                              value: event.category,
                            ),
                            const Divider(height: 24),
                            _DetailRow(
                              icon: Iconsax.status,
                              label: 'Status',
                              value: event.status,
                            ),
                            if (event.teamType == 'team') ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Iconsax.user_octagon,
                                label: 'Min Team Size',
                                value: '${event.teamSizeMin}',
                              ),
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Iconsax.user_octagon,
                                label: 'Max Team Size',
                                value: '${event.teamSizeMax}',
                              ),
                            ],
                            if (event.registrationFee != null && event.registrationFee! > 0) ...[
                              const Divider(height: 24),
                              _DetailRow(
                                icon: Iconsax.money,
                                label: 'Fee',
                                value: 'NPR ${event.registrationFee!.toStringAsFixed(0)}',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ref.invalidate(eventDetailProvider(eventId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: eventAsync.maybeWhen(
        data: (event) => event != null && event.status.toLowerCase() != 'completed'
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Iconsax.ticket, size: 16, color: ModernTheme.primaryOrange),
                            const SizedBox(width: 4),
                            Text(
                              'NPR ${event.registrationFee?.toStringAsFixed(0) ?? '10'}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ModernTheme.primaryOrange,
                                  ),
                            ),
                          ],
                        ),
                        Text(
                          'Registration Fee',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GradientButton(
                        text: 'Register Now',
                        icon: Iconsax.tick_circle,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Registration coming soon!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ModernTheme.primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time;
  final String title;
  final String description;
  final Color color;
  final bool isLast;

  const _ScheduleItem({
    required this.time,
    required this.title,
    required this.description,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(
                time,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, size: 20, color: ModernTheme.primaryOrange),
      ),
    );
  }
}
