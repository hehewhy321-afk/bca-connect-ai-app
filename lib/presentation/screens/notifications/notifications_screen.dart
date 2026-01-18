import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/connectivity_service.dart';
import 'dart:convert';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String selectedFilter = 'All';
  final filters = ['All', 'Unread', 'Events', 'Forum', 'System'];
  bool _loading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    
    final cacheKey = '${CacheKeys.notifications}_${user.id}';
    
    // Try to load from cache first
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final notificationsList = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
        
        if (mounted) {
          setState(() {
            _notifications = notificationsList;
            _loading = false;
          });
        }
        
        debugPrint('Loaded ${notificationsList.length} notifications from cache');
      }
    } catch (e) {
      debugPrint('Error loading notifications from cache: $e');
    }
    
    // Check connectivity
    final connectivity = ConnectivityService();
    final isOnline = await connectivity.isOnline();
    
    if (!isOnline) {
      // If offline and we have cached data, we're done
      if (_notifications.isNotEmpty) {
        debugPrint('Offline: Using cached notifications');
        return;
      }
      // If offline and no cache, show error
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Iconsax.wifi_square, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('No internet connection')),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Fetch from network
    try {
      final response = await SupabaseConfig.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        final notificationsList = List<Map<String, dynamic>>.from(response);
        
        // Cache the results
        await CacheService.set(
          cacheKey,
          jsonEncode(notificationsList),
          duration: CacheKeys.shortCache,
        );
        
        setState(() {
          _notifications = notificationsList;
          _loading = false;
        });
        
        debugPrint('Fetched and cached ${notificationsList.length} notifications');
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() => _loading = false);
        // If we have cached data, don't show error
        if (_notifications.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Iconsax.danger, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error loading notifications: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(String notificationId, String? link) async {
    try {
      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });

      // Open link if provided
      if (link != null && link.isNotEmpty) {
        await _openLink(link);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openLink(String link) async {
    try {
      // Add https:// if protocol is missing
      String urlString = link.trim();
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      
      final uri = Uri.parse(urlString);
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      await SupabaseConfig.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((notification) {
      final type = notification['type']?.toString() ?? 'info';
      final isRead = notification['is_read'] == true;

      if (selectedFilter == 'All') return true;
      if (selectedFilter == 'Unread') return !isRead;
      if (selectedFilter == 'Events') return type == 'event';
      if (selectedFilter == 'Forum') return type == 'forum';
      if (selectedFilter == 'System') return type == 'system' || type == 'info';
      return true;
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] != true).length;

  @override
  Widget build(BuildContext context) {
    final notifications = _filteredNotifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Modern App Bar
                SliverAppBar(
                  expandedHeight: 140,
                  floating: false,
                  pinned: true,
                  backgroundColor: isDark ? const Color(0xFF000000) : Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFDA7809),
                            Color(0xFFFF9500),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Iconsax.notification,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Notifications',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  if (_unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$_unreadCount',
                                        style: const TextStyle(
                                          color: Color(0xFFDA7809),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (_unreadCount > 0)
                      IconButton(
                        icon: const Icon(Iconsax.tick_circle),
                        onPressed: _markAllAsRead,
                        tooltip: 'Mark all as read',
                      ),
                  ],
                ),

                // Filter Chips
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final filter = entry.value;
                          final isSelected = selectedFilter == filter;
                          return Padding(
                            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
                            child: _FilterChip(
                              label: filter,
                              isSelected: isSelected,
                              onTap: () => setState(() => selectedFilter = filter),
                            ),
                          ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.2);
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                // Notifications List
                notifications.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(filter: selectedFilter),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final notification = notifications[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < notifications.length - 1 ? 12 : 0,
                                ),
                                child: _ModernNotificationCard(
                                  notification: notification,
                                  onTap: () => _markAsRead(
                                    notification['id'],
                                    notification['link'],
                                  ),
                                  index: index,
                                ),
                              );
                            },
                            childCount: notifications.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFDA7809), Color(0xFFFF9500)],
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : isDark
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFDA7809).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.grey[400]
                    : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ModernNotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final int index;

  const _ModernNotificationCard({
    required this.notification,
    required this.onTap,
    required this.index,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case 'event':
        return Iconsax.calendar;
      case 'forum':
        return Iconsax.message_text;
      case 'achievement':
        return Iconsax.award;
      case 'system':
        return Iconsax.notification_bing;
      default:
        return Iconsax.notification;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'event':
        return const Color(0xFFDA7809);
      case 'forum':
        return const Color(0xFF8B5CF6);
      case 'achievement':
        return const Color(0xFFFFC107);
      case 'system':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFDA7809);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRead = notification['is_read'] == true;
    final type = notification['type']?.toString() ?? 'info';
    final color = _getColorForType(type);
    final icon = _getIconForType(type);
    final hasLink = notification['link'] != null && notification['link'].toString().isNotEmpty;
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'])
        : DateTime.now();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? (isRead ? const Color(0xFF1A1A1A) : const Color(0xFF1F1F1F))
              : (isRead ? Colors.white : const Color(0xFFFFF8F0)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? (isDark ? Colors.grey.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1))
                : color.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification['message'] ?? '',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 14,
                          color: isDark ? Colors.grey[600] : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimestamp(createdAt),
                          style: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasLink) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withValues(alpha: 0.15),
                                  color.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.link,
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Open Link',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _EmptyState extends StatelessWidget {
  final String filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFDA7809).withValues(alpha: 0.1),
                  const Color(0xFFFF9500).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.notification_status,
              size: 80,
              color: const Color(0xFFDA7809).withValues(alpha: 0.5),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            filter == 'All' ? 'No Notifications' : 'No $filter Notifications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontSize: 22,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              filter == 'All'
                  ? 'You\'re all caught up!\nNo new notifications at the moment.'
                  : 'No notifications in this category.\nTry selecting a different filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}
