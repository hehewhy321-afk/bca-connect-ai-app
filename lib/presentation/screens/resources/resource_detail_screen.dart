import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../data/models/resource.dart';
import '../../../data/repositories/resource_repository.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/gradient_button.dart';

final resourceDetailProvider = FutureProvider.family<Resource?, String>((ref, resourceId) async {
  final repo = ResourceRepository();
  return await repo.getResourceById(resourceId);
});

class ResourceDetailScreen extends ConsumerWidget {
  final String resourceId;

  const ResourceDetailScreen({super.key, required this.resourceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourceAsync = ref.watch(resourceDetailProvider(resourceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Details'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.share),
            onPressed: () {},
          ),
        ],
      ),
      body: resourceAsync.when(
        data: (resource) {
          if (resource == null) {
            return const Center(child: Text('Resource not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: ModernTheme.orangeGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getResourceIcon(resource.type),
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  resource.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Type & Category
                Wrap(
                  spacing: 8,
                  children: [
                    _InfoChip(
                      icon: Iconsax.document,
                      label: resource.type,
                      color: ModernTheme.primaryOrange,
                    ),
                    if (resource.category != null)
                      _InfoChip(
                        icon: Iconsax.category,
                        label: resource.category!,
                        color: ModernTheme.accentOrange,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    _StatItem(
                      icon: Iconsax.eye,
                      value: resource.views.toString(),
                      label: 'Views',
                    ),
                    const SizedBox(width: 24),
                    _StatItem(
                      icon: Iconsax.document_download,
                      value: resource.downloads.toString(),
                      label: 'Downloads',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Description
                if (resource.description != null) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resource.description!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Subject & Semester
                if (resource.subject != null || resource.semester != null) ...[
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (resource.subject != null)
                    _DetailRow(label: 'Subject', value: resource.subject!),
                  if (resource.semester != null)
                    _DetailRow(label: 'Semester', value: 'Semester ${resource.semester}'),
                ],
                const SizedBox(height: 100),
              ],
            ),
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: resourceAsync.maybeWhen(
        data: (resource) => resource != null
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
                child: GradientButton(
                  text: 'Download Resource',
                  icon: Iconsax.document_download,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Download feature coming soon!')),
                    );
                  },
                ),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  IconData _getResourceIcon(String type) {
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
