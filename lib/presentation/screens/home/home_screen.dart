import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/event_provider.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../core/services/notification_listener_service.dart';
import '../../../core/services/permission_service.dart';
import '../events/enhanced_events_screen.dart';
import '../forum/enhanced_forum_screen.dart';
import '../resources/enhanced_resources_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/cached_image.dart';
import '../../widgets/offline_indicator.dart';
import '../../widgets/daily_quote_card.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);
final lastBackPressProvider = StateProvider<DateTime?>((ref) => null);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _permissionsRequested = false;

  @override
  void initState() {
    super.initState();
    // Start listening for notifications
    NotificationListenerService().startListening();
    
    // Request permissions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    
    // Request all necessary permissions
    await PermissionService().requestInitialPermissions(context);
  }

  @override
  void dispose() {
    // Stop listening when screen is disposed
    NotificationListenerService().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    final screens = [
      const DashboardTab(),
      const EnhancedEventsScreen(),
      const EnhancedForumScreen(),
      const EnhancedResourcesScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If not on dashboard, go to dashboard first
        if (selectedIndex != 0) {
          ref.read(selectedIndexProvider.notifier).state = 0;
          return;
        }
        
        // If on dashboard, check for double back press
        final lastBackPress = ref.read(lastBackPressProvider);
        final now = DateTime.now();
        
        if (lastBackPress == null || now.difference(lastBackPress) > const Duration(seconds: 2)) {
          // First back press or timeout - show toast
          ref.read(lastBackPressProvider.notifier).state = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Second back press within 2 seconds - exit app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            ref.read(selectedIndexProvider.notifier).state = index;
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.home),
              selectedIcon: Icon(Iconsax.home5),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.calendar),
              selectedIcon: Icon(Iconsax.calendar5),
              label: 'Events',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.message_text),
              selectedIcon: Icon(Iconsax.message_text5),
              label: 'Forum',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.folder),
              selectedIcon: Icon(Iconsax.folder5),
              label: 'Resources',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.user),
              selectedIcon: Icon(Iconsax.profile_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingEventsAsync = ref.watch(upcomingEventsProvider);
    final announcementsAsync = ref.watch(activeAnnouncementsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Offline Indicator in AppBar
          const OfflineIndicatorCompact(),
          unreadCountAsync.when(
            data: (count) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Iconsax.notification),
                  onPressed: () => context.push('/notifications'),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDA7809),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        count > 99 ? '99+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            loading: () => IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () => context.push('/notifications'),
            ),
            error: (error, stackTrace) => IconButton(
              icon: const Icon(Iconsax.notification),
              onPressed: () => context.push('/notifications'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_ai_fab',
        onPressed: () => context.push('/ai-assistant'),
        backgroundColor: const Color(0xFFDA7809),
        child: const Icon(Iconsax.message_programming, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(upcomingEventsProvider);
          ref.invalidate(activeAnnouncementsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notices Section - Show first if available
              announcementsAsync.when(
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              
                              const SizedBox(width: 8),
                              Text(
                                'Notices',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => context.push('/notices'),
                            child: const Text('See all', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...announcements.take(3).map((announcement) => _NoticeCard(
                            announcement: announcement,
                          )),
                      const SizedBox(height: 24),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // Daily Quote/Tip Card
              const DailyQuoteCard(),

              // Quick Actions - Bento Grid
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Bento Grid Layout (2x3)
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.calendar_2,
                      label: 'नेपाली पात्रो',
                      color: const Color(0xFFDC2626),
                      onTap: () => context.push('/calendar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.timer_1,
                      label: 'Pomodoro',
                      color: const Color(0xFF3B82F6),
                      onTap: () => context.push('/pomodoro'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.book_1,
                      label: 'Study Planner',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.push('/study'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.wallet_money,
                      label: 'Finance',
                      color: const Color(0xFFEC4899),
                      onTap: () => context.push('/finance'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.people,
                      label: 'Community',
                      color: const Color(0xFFFF9500),
                      onTap: () => context.push('/community'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.document_text,
                      label: 'Notices',
                      color: const Color(0xFF10B981),
                      onTap: () => context.push('/notices'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.game,
                      label: 'Algorithm Game',
                      color: const Color(0xFF6366F1),
                      onTap: () => context.push('/algorithm-game'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCard(
                      icon: Iconsax.emoji_happy,
                      label: 'Fun Zone',
                      color: const Color(0xFFEC4899),
                      onTap: () => context.push('/fun-zone'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Upcoming Events with Full Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                    
                      const SizedBox(width: 8),
                      Text(
                        'Upcoming Events',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => ref.read(selectedIndexProvider.notifier).state = 1,
                    child: const Text('See all', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              upcomingEventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          style: BorderStyle.solid,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Iconsax.calendar_remove,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No upcoming events',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: events.take(2).map((event) => _FullEventCard(event: event)).toList(),
                  );
                },
                loading: () => const Column(
                  children: [
                    EventCardSkeleton(),
                    SizedBox(height: 16),
                    EventCardSkeleton(),
                  ],
                ),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Error loading events',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Website Promotion Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDA7809).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Iconsax.global,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Visit Our Web Platform',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Access more features on desktop',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Get the full experience with advanced analytics, detailed reports, and enhanced collaboration tools on our web platform.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse('https://mmamc-bca.vercel.app');
                              try {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to open website: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Iconsax.export_1, size: 18),
                            label: const Text('Open Website'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFDA7809),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Bento Card Widget for Quick Actions
class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BentoCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Event Card with Image
class _FullEventCard extends StatelessWidget {
  final dynamic event;

  const _FullEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Image or Gradient Placeholder
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                CachedImage(
                  imageUrl: event.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  errorWidget: Container(
                    height: 140,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Iconsax.calendar_1,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Iconsax.calendar_1,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              // Event Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dateFormat.format(event.startDate)} • ${timeFormat.format(event.startDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notice Card Widget
class _NoticeCard extends StatelessWidget {
  final dynamic announcement;

  const _NoticeCard({required this.announcement});

  Color _getColorForType(BuildContext context, String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Iconsax.warning_2;
      case 'error':
        return Iconsax.danger;
      case 'success':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(context, announcement.type);
    final icon = _getIconForType(announcement.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show full notice details
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _NoticeDetailSheet(announcement: announcement),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.content,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Notice Detail Sheet
class _NoticeDetailSheet extends StatelessWidget {
  final dynamic announcement;

  const _NoticeDetailSheet({required this.announcement});

  Color _getColorForType(BuildContext context, String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'warning':
        return Iconsax.warning_2;
      case 'error':
        return Iconsax.danger;
      case 'success':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(context, announcement.type);
    final icon = _getIconForType(announcement.type);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                announcement.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
