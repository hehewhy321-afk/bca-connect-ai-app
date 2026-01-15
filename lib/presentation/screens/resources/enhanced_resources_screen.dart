import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../core/config/supabase_config.dart';

// Provider for all resources
final allResourcesProvider = FutureProvider<List<Resource>>((ref) async {
  final repo = ResourceRepository();
  return await repo.getResources();
});

// State providers for filters
final resourceSearchQueryProvider = StateProvider<String>((ref) => '');
final resourceSelectedTypeProvider = StateProvider<String>((ref) => 'all');
final resourceSelectedSemesterProvider = StateProvider<String>((ref) => 'all');

// Filtered resources provider
final filteredResourcesProvider = Provider<AsyncValue<List<Resource>>>((ref) {
  final resourcesAsync = ref.watch(allResourcesProvider);
  final searchQuery = ref.watch(resourceSearchQueryProvider).toLowerCase();
  final selectedType = ref.watch(resourceSelectedTypeProvider);
  final selectedSemester = ref.watch(resourceSelectedSemesterProvider);

  return resourcesAsync.whenData((resources) {
    return resources.where((resource) {
      final matchesSearch = resource.title.toLowerCase().contains(searchQuery) ||
          (resource.description?.toLowerCase().contains(searchQuery) ?? false) ||
          (resource.subject?.toLowerCase().contains(searchQuery) ?? false);
      final matchesType = selectedType == 'all' || resource.type.toLowerCase() == selectedType.toLowerCase();
      final matchesSemester = selectedSemester == 'all' ||
          (resource.semester?.toString() == selectedSemester);
      return matchesSearch && matchesType && matchesSemester;
    }).toList();
  });
});

class EnhancedResourcesScreen extends ConsumerWidget {
  const EnhancedResourcesScreen({super.key});

  Future<void> _handleResourceView(BuildContext context, WidgetRef ref, Resource resource) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;

      // Increment view count
      await SupabaseConfig.client
          .from('resources')
          .update({'views': resource.views + 1}).eq('id', resource.id);

      // Track download if user is authenticated
      if (user != null) {
        try {
          await SupabaseConfig.client.from('resource_downloads').insert({
            'resource_id': resource.id,
            'user_id': user.id,
          });

          // Increment downloads count
          await SupabaseConfig.client
              .from('resources')
              .update({'downloads': resource.downloads + 1}).eq('id', resource.id);
        } catch (e) {
          // Ignore duplicate key errors
          if (!e.toString().contains('duplicate')) {
            debugPrint('Error tracking download: $e');
          }
        }
      }

      // Open the resource
      final url = resource.externalUrl ?? resource.fileUrl;
      if (url != null) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      }

      // Refresh resources to get updated counts
      ref.invalidate(allResourcesProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening resource...')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open resource: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredResourcesAsync = ref.watch(filteredResourcesProvider);
    final searchQuery = ref.watch(resourceSearchQueryProvider);
    final selectedType = ref.watch(resourceSelectedTypeProvider);
    final selectedSemester = ref.watch(resourceSelectedSemesterProvider);

    final types = [
      'all',
      'study_material',
      'past_paper',
      'project',
      'interview_prep',
      'article'
    ];

    final semesters = ['all', '1', '2', '3', '4', '5', '6', '7', '8'];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resource Hub', style: TextStyle(fontSize: 20)),
            Text(
              'Study materials and resources',
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
              onChanged: (value) => ref.read(resourceSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search resources...',
                prefixIcon: const Icon(Iconsax.search_normal_1),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: () => ref.read(resourceSearchQueryProvider.notifier).state = '',
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

          // Filter Pills
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
                    ref.read(resourceSelectedTypeProvider.notifier).state = type;
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

          // Semester Pills
          SizedBox(
            height: 50,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: semesters.length,
              separatorBuilder: (context, error) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final semester = semesters[index];
                final isSelected = selectedSemester == semester;
                return FilterChip(
                  label: Text(semester == 'all' ? 'All Semesters' : 'Sem $semester'),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(resourceSelectedSemesterProvider.notifier).state = semester;
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

          // Resources Grid
          Expanded(
            child: filteredResourcesAsync.when(
              data: (resources) {
                if (resources.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.folder_open,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No resources found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
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
                    ref.invalidate(allResourcesProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 1.3,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      return _ResourceCard(
                        resource: resources[index],
                        onTap: () => _handleResourceView(context, ref, resources[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  childAspectRatio: 1.3,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Container(
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
                      'Error loading resources',
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
                      onPressed: () => ref.invalidate(allResourcesProvider),
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
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final VoidCallback onTap;

  const _ResourceCard({
    required this.resource,
    required this.onTap,
  });

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'study_material':
        return Iconsax.book;
      case 'past_paper':
        return Iconsax.document_text;
      case 'project':
        return Iconsax.code;
      case 'interview_prep':
        return Iconsax.briefcase;
      case 'article':
        return Iconsax.note;
      default:
        return Iconsax.document;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'study_material':
        return ModernTheme.primaryOrange;
      case 'past_paper':
        return const Color(0xFF8B5CF6);
      case 'project':
        return const Color(0xFF3B82F6);
      case 'interview_prep':
        return const Color(0xFFEC4899);
      case 'article':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  String _formatType(String type) {
    return type.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(resource.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForType(resource.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              resource.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Description
            if (resource.description != null)
              Text(
                resource.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const Spacer(),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatType(resource.type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (resource.semester != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sem ${resource.semester}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (resource.subject != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      resource.subject!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats and Action
            Row(
              children: [
                Row(
                  children: [
                    Icon(Iconsax.eye, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${resource.views}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 12),
                    Icon(Iconsax.document_download, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${resource.downloads}', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.export_1, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Open',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
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
    );
  }
}
