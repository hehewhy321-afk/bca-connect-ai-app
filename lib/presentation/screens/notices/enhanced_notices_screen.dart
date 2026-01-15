import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../../data/models/announcement.dart';

// Provider for all notices
final allNoticesProvider = FutureProvider<List<Announcement>>((ref) async {
  final repo = AnnouncementRepository();
  return await repo.getAllAnnouncements();
});

// State providers for search and filters
final noticeSearchQueryProvider = StateProvider<String>((ref) => '');
final noticeSelectedTypeProvider = StateProvider<String>((ref) => 'all');
final noticeSelectedStatusProvider = StateProvider<String>((ref) => 'all');

// Filtered notices provider
final filteredNoticesProvider = Provider<AsyncValue<List<Announcement>>>((ref) {
  final noticesAsync = ref.watch(allNoticesProvider);
  final searchQuery = ref.watch(noticeSearchQueryProvider).toLowerCase();
  final selectedType = ref.watch(noticeSelectedTypeProvider);
  final selectedStatus = ref.watch(noticeSelectedStatusProvider);

  return noticesAsync.whenData((notices) {
    return notices.where((notice) {
      final matchesSearch = notice.title.toLowerCase().contains(searchQuery) ||
          notice.content.toLowerCase().contains(searchQuery);
      
      final matchesType = selectedType == 'all' || 
          notice.type.toLowerCase() == selectedType.toLowerCase();
      
      final isExpired = notice.expiresAt != null && notice.expiresAt!.isBefore(DateTime.now());
      final matchesStatus = selectedStatus == 'all' ||
          (selectedStatus == 'active' && !isExpired) ||
          (selectedStatus == 'expired' && isExpired) ||
          (selectedStatus == 'pinned' && notice.isActive);
      
      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  });
});

class EnhancedNoticesScreen extends ConsumerWidget {
  const EnhancedNoticesScreen({super.key});

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
    final filteredNoticesAsync = ref.watch(filteredNoticesProvider);
    final searchQuery = ref.watch(noticeSearchQueryProvider);
    final selectedType = ref.watch(noticeSelectedTypeProvider);
    final selectedStatus = ref.watch(noticeSelectedStatusProvider);

    final types = ['all', 'info', 'warning', 'urgent', 'success'];
    final statuses = ['all', 'active', 'expired', 'pinned'];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notices & Announcements', style: TextStyle(fontSize: 20)),
            Text(
              'Important updates and information',
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
              onChanged: (value) => ref.read(noticeSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search notices...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: () => ref.read(noticeSearchQueryProvider.notifier).state = '',
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

          // Type Filter Pills
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: types.length,
              separatorBuilder: (context, error) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final type = types[index];
                final isSelected = selectedType == type;
                return FilterChip(
                  label: Text(_formatType(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(noticeSelectedTypeProvider.notifier).state = type;
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: _getPriorityColor(type),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? _getPriorityColor(type)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Status Filter Pills
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (context, error) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = statuses[index];
                final isSelected = selectedStatus == status;
                return FilterChip(
                  label: Text(_formatStatus(status)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(noticeSelectedStatusProvider.notifier).state = status;
                  },
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: const Color(0xFF8B5CF6),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Notices List
          Expanded(
            child: filteredNoticesAsync.when(
              data: (notices) {
                if (notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty ? 'No notices found' : 'No notices available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try adjusting your filters'
                              : 'There are no notices at this time',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }

                // Separate pinned and regular notices
                final pinnedNotices = notices.where((n) => n.isActive).toList();
                final regularNotices = notices.where((n) => !n.isActive).toList();

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allNoticesProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Pinned Notices
                      if (pinnedNotices.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Iconsax.bookmark5, size: 20, color: ModernTheme.primaryOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Pinned Notices',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pinnedNotices.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: ModernTheme.primaryOrange,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 12),
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
                        Row(
                          children: [
                            Icon(Iconsax.document_text5, size: 20, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'All Notices',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${regularNotices.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                        const SizedBox(height: 12),
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
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    height: 150,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
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
                      'Error loading notices',
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
                      onPressed: () => ref.invalidate(allNoticesProvider),
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
    );
  }

  String _formatType(String type) {
    if (type == 'all') return 'All Types';
    return type[0].toUpperCase() + type.substring(1);
  }

  String _formatStatus(String status) {
    if (status == 'all') return 'All Status';
    return status[0].toUpperCase() + status.substring(1);
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
      child: InkWell(
        onTap: () {
          // Could navigate to detail screen
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Iconsax.bookmark5, size: 12, color: Colors.white),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
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
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.2);
  }
}
