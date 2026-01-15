import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/models/announcement.dart';

final noticesProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = AnnouncementRepository();
  return await repo.getAllAnnouncements();
});

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  Color _getPriorityColor(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Colors.orange;
      case 'error':
      case 'urgent':
        return Colors.red;
      case 'success':
        return Colors.green;
      default:
        return ModernTheme.primaryOrange;
    }
  }

  IconData _getPriorityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'warning':
        return Iconsax.warning_2;
      case 'error':
      case 'urgent':
        return Iconsax.danger;
      case 'success':
        return Iconsax.tick_circle;
      default:
        return Iconsax.info_circle;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Iconsax.document_text5, color: ModernTheme.primaryOrange),
            SizedBox(width: 12),
            Text('Notices & Announcements'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => ref.invalidate(noticesProvider),
          ),
        ],
      ),
      body: noticesAsync.when(
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Iconsax.document_text,
                    size: 80,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ).animate().scale(duration: 500.ms),
                  const SizedBox(height: 24),
                  Text(
                    'No Notices Available',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are no notices or announcements at this time',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Separate pinned and regular notices
          final pinnedNotices = notices.where((n) => n.isActive).toList();
          final regularNotices = notices.where((n) => !n.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(noticesProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Pinned Notices
                if (pinnedNotices.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Iconsax.bookmark, size: 20, color: ModernTheme.primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Pinned Notices',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 16),
                  ...pinnedNotices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final notice = entry.value;
                    return _NoticeCard(
                      notice: notice,
                      isPinned: true,
                      getPriorityColor: _getPriorityColor,
                      getPriorityIcon: _getPriorityIcon,
                      index: index,
                    );
                  }),
                  const SizedBox(height: 24),
                ],

                // Regular Notices
                if (regularNotices.isNotEmpty) ...[
                  Text(
                    'All Notices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                  const SizedBox(height: 16),
                  ...regularNotices.asMap().entries.map((entry) {
                    final index = entry.key + pinnedNotices.length;
                    final notice = entry.value;
                    return _NoticeCard(
                      notice: notice,
                      isPinned: false,
                      getPriorityColor: _getPriorityColor,
                      getPriorityIcon: _getPriorityIcon,
                      index: index,
                    );
                  }),
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
              Icon(
                Iconsax.close_circle,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading notices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(noticesProvider),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Announcement notice;
  final bool isPinned;
  final Color Function(String) getPriorityColor;
  final IconData Function(String) getPriorityIcon;
  final int index;

  const _NoticeCard({
    required this.notice,
    required this.isPinned,
    required this.getPriorityColor,
    required this.getPriorityIcon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor(notice.type);
    final icon = getPriorityIcon(notice.type);
    final isExpired = notice.expiresAt != null && notice.expiresAt!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPinned
              ? ModernTheme.primaryOrange.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: isPinned ? 2 : 1,
        ),
        boxShadow: isPinned
            ? [
                BoxShadow(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isPinned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: ModernTheme.orangeGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.bookmark, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Pinned',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (notice.type.toLowerCase() != 'info')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              notice.type.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'EXPIRED',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      notice.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            notice.content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              Icon(
                Iconsax.calendar,
                size: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd, yyyy').format(notice.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (notice.expiresAt != null) ...[
                const SizedBox(width: 16),
                Icon(
                  Iconsax.clock,
                  size: 14,
                  color: isExpired ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expires: ${DateFormat('MMM dd').format(notice.expiresAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isExpired ? Colors.red : Colors.orange,
                      ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.2);
  }
}
