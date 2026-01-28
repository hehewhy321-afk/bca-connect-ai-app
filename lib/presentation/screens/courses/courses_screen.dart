import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/course.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/course_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _priceFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filterCourses(List<Course> courses) {
    return courses.where((course) {
      final matchesSearch = _searchQuery.isEmpty ||
          course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (course.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (course.category?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesPrice = _priceFilter == 'all' ||
          (_priceFilter == 'free' && course.price == 0) ||
          (_priceFilter == 'paid' && course.price > 0);

      final matchesCategory = _categoryFilter == 'all' || course.category == _categoryFilter;

      return matchesSearch && matchesPrice && matchesCategory;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(publishedCoursesProvider);
    final enrollmentsAsync = ref.watch(userEnrollmentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: coursesAsync.when(
        data: (courses) {
          final categories = courses
              .map((c) => c.category)
              .where((c) => c != null && c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          final filteredCourses = _filterCourses(courses);

          return CustomScrollView(
            slivers: [
              // Modern App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Theme.of(context).colorScheme.surface,
                surfaceTintColor: Colors.transparent,
                expandedHeight: 280,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ModernTheme.primaryOrange.withValues(alpha: 0.15),
                          ModernTheme.primaryOrange.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, courses.length, filteredCourses.length),
                            const SizedBox(height: 20),
                            _buildSearchBar(context),
                            const SizedBox(height: 16),
                            _buildFilters(context, categories),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Courses List
              if (filteredCourses.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.search_normal,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No courses found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList.builder(
                    itemCount: filteredCourses.length,
                    itemBuilder: (context, index) {
                      final course = filteredCourses[index];
                      final enrollment = enrollmentsAsync.value?.firstWhere(
                        (e) => e.courseId == course.id,
                        orElse: () => CourseEnrollment(
                          id: '',
                          userId: '',
                          courseId: '',
                          status: EnrollmentStatus.pending,
                          enrolledAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );

                      final isEnrolled = enrollment != null && enrollment.id.isNotEmpty;
                      final isApproved = enrollment?.status == EnrollmentStatus.approved;

                      return _BigCourseCard(
                        course: course,
                        isEnrolled: isEnrolled,
                        isApproved: isApproved,
                      );
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Convert technical errors to user-friendly messages
          String userMessage;
          IconData errorIcon;
          
          final errorString = error.toString().toLowerCase();
          
          if (errorString.contains('no internet') || 
              errorString.contains('network') || 
              errorString.contains('connection') ||
              errorString.contains('timeout')) {
            userMessage = 'No Internet Connection\nPlease check your network and try again';
            errorIcon = Iconsax.wifi;
          } else if (errorString.contains('server') || 
                     errorString.contains('503') || 
                     errorString.contains('502')) {
            userMessage = 'Server Temporarily Unavailable\nPlease try again in a few minutes';
            errorIcon = Iconsax.cloud_minus;
          } else if (errorString.contains('cached') || 
                     errorString.contains('cache')) {
            userMessage = 'Unable to Load Courses\nPlease check your connection';
            errorIcon = Iconsax.refresh;
          } else {
            userMessage = 'Something Went Wrong\nPlease try again later';
            errorIcon = Iconsax.danger;
          }
          
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      errorIcon, 
                      size: 48, 
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    userMessage.split('\n').first,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userMessage.split('\n').length > 1 ? userMessage.split('\n')[1] : '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(publishedCoursesProvider),
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalCourses, int filteredCount) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: ModernTheme.orangeGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Iconsax.video_play, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Video Courses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
              Text(
                '$totalCourses courses • $filteredCount results',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            ref.invalidate(publishedCoursesProvider);
            ref.invalidate(userEnrollmentsProvider);
          },
          icon: const Icon(Iconsax.refresh),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search courses...',
          prefixIcon: const Icon(Iconsax.search_normal_1),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, List<String?> categories) {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            context: context,
            value: _priceFilter,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Prices')),
              DropdownMenuItem(value: 'free', child: Text('Free Only')),
              DropdownMenuItem(value: 'paid', child: Text('Paid Only')),
            ],
            onChanged: (value) => setState(() => _priceFilter = value!),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildDropdown(
            context: context,
            value: _categoryFilter,
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Categories')),
              ...categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text('📁 $cat'),
                  )),
            ],
            onChanged: (value) => setState(() => _categoryFilter = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Iconsax.arrow_down_1, size: 18),
          style: Theme.of(context).textTheme.bodyMedium,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _BigCourseCard extends StatelessWidget {
  final Course course;
  final bool isEnrolled;
  final bool isApproved;

  const _BigCourseCard({
    required this.course,
    required this.isEnrolled,
    required this.isApproved,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: InkWell(
          onTap: () => context.push('/courses/${course.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(context),
              _buildContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: course.thumbnailUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 800,
                  memCacheHeight: 450,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ModernTheme.primaryOrange.withValues(alpha: 0.2),
                          ModernTheme.primaryOrange.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: ModernTheme.primaryOrange, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEnrolled) _buildEnrollmentBadge(),
              if (course.category != null) _buildCategoryBadge(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ModernTheme.primaryOrange.withValues(alpha: 0.2),
            ModernTheme.primaryOrange.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Icon(
        Iconsax.video_play,
        size: 60,
        color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEnrollmentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isApproved ? Colors.green : Colors.orange).withValues(alpha: 0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved ? Iconsax.tick_circle5 : Iconsax.clock,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isApproved ? 'Enrolled' : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        course.category!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (course.description != null && course.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              course.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPriceBadge(),
              _buildActionButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: course.price > 0 ? ModernTheme.orangeGradient : null,
        color: course.price == 0 ? Colors.green.withValues(alpha: 0.15) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        course.price > 0 ? 'NPR ${course.price.toStringAsFixed(0)}' : 'FREE',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: course.price > 0 ? Colors.white : Colors.green,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: ModernTheme.orangeGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.arrow_right_3,
        size: 20,
        color: Colors.white,
      ),
    );
  }
}
