import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/course.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> with SingleTickerProviderStateMixin {
  final _transactionIdController = TextEditingController();
  String? _paymentScreenshotPath;
  bool _isUploading = false;
  final Set<String> _expandedChapters = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _paymentScreenshotPath = image.path);
    }
  }

  Future<void> _enrollInCourse(Course course) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final repository = ref.read(courseRepositoryProvider);
      String? screenshotUrl;
      if (_paymentScreenshotPath != null) {
        screenshotUrl = await repository.uploadPaymentScreenshot(user.id, _paymentScreenshotPath!);
      }

      await repository.enrollInCourse(
        userId: user.id,
        courseId: course.id,
        paymentScreenshotUrl: screenshotUrl,
        transactionId: _transactionIdController.text.trim().isEmpty ? null : _transactionIdController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Iconsax.tick_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Enrollment submitted! Awaiting approval.')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
        ref.invalidate(enrollmentStatusProvider(widget.courseId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Iconsax.danger, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showEnrollDialog(Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: ModernTheme.orangeGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Iconsax.card, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Enroll in Course', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Pay NPR ${course.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Image.network('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=esewa_payment', width: 200, height: 200, fit: BoxFit.contain),
                      const SizedBox(height: 12),
                      const Text('Scan to pay via eSewa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Payment Screenshot', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _paymentScreenshotPath != null ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _paymentScreenshotPath != null ? ModernTheme.primaryOrange.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Iconsax.gallery, color: _paymentScreenshotPath != null ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _paymentScreenshotPath != null ? 'Screenshot selected ✓' : 'Tap to upload screenshot',
                          style: TextStyle(color: _paymentScreenshotPath != null ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: _paymentScreenshotPath != null ? FontWeight.w600 : FontWeight.normal),
                        ),
                      ),
                      if (_paymentScreenshotPath != null) const Icon(Iconsax.tick_circle5, color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transactionIdController,
                decoration: InputDecoration(
                  labelText: 'Transaction ID (Optional)',
                  hintText: 'e.g., TXN-123456',
                  prefixIcon: const Icon(Iconsax.receipt_text),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _paymentScreenshotPath != null && !_isUploading ? () => _enrollInCourse(course) : null,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.tick_circle), SizedBox(width: 8), Text('Submit Payment')]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final chaptersAsync = ref.watch(courseChaptersProvider(widget.courseId));
    final enrollmentAsync = ref.watch(enrollmentStatusProvider(widget.courseId));

    return Scaffold(
      body: courseAsync.when(
        data: (course) {
          final enrollment = enrollmentAsync.value;
          final isApproved = enrollment?.status == EnrollmentStatus.approved;
          final isPending = enrollment?.status == EnrollmentStatus.pending;
          final isFree = course.price == 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                automaticallyImplyLeading: true, // Keep back button for detail screen
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Builder(
                        builder: (context) {
                          if (course.thumbnailUrl == null || course.thumbnailUrl!.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                    ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Iconsax.video_play,
                                size: 80,
                                color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
                              ),
                            );
                          }

                          return CachedNetworkImage(
                            imageUrl: course.thumbnailUrl!,
                            fit: BoxFit.cover,
                            httpHeaders: const {
                              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                            },
                            cacheManager: null,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                    ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: ModernTheme.primaryOrange),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ModernTheme.primaryOrange.withValues(alpha: 0.3),
                                      ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.video_play,
                                  size: 80,
                                  color: ModernTheme.primaryOrange.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (course.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(gradient: ModernTheme.orangeGradient, borderRadius: BorderRadius.circular(8)),
                          child: Text(course.category!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      const SizedBox(height: 12),
                      Text(course.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      const SizedBox(height: 12),
                      // Show half description (2 lines max)
                      if (course.description != null) 
                        Text(
                          course.description!, 
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant, 
                            height: 1.6
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 24),
                      // Price and Enroll Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [ModernTheme.primaryOrange.withValues(alpha: 0.1), ModernTheme.primaryOrange.withValues(alpha: 0.05)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ModernTheme.primaryOrange.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Course Price', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 4),
                                  Text(course.price > 0 ? 'NPR ${course.price.toStringAsFixed(0)}' : 'FREE', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: ModernTheme.primaryOrange)),
                                ],
                              ),
                            ),
                            if (isApproved || isFree)
                              ElevatedButton.icon(
                                onPressed: () => context.push('/courses/${course.id}/learn'),
                                icon: const Icon(Iconsax.play_circle),
                                label: const Text('Start Learning'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              )
                            else if (isPending)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Iconsax.clock, color: Colors.orange), SizedBox(width: 8), Text('Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
                              )
                            else
                              ElevatedButton.icon(
                                onPressed: () => _showEnrollDialog(course),
                                icon: const Icon(Iconsax.card),
                                label: const Text('Enroll Now'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: ModernTheme.primaryOrange,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: ModernTheme.primaryOrange,
                    indicatorWeight: 3,
                    tabs: const [Tab(text: 'Course Content'), Tab(text: 'About')],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    chaptersAsync.when(
                      data: (chapters) => _buildCourseContent(chapters, isApproved, isFree),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                    ),
                    _buildAboutTab(course),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Iconsax.danger, size: 48, color: Colors.red), const SizedBox(height: 16), Text('Error: $error')])),
      ),
    );
  }

  Widget _buildCourseContent(List<CourseChapter> chapters, bool isApproved, bool isFree) {
    if (chapters.isEmpty) return const Center(child: Text('No content available'));
    
    // Auto-expand first chapter only on initial load
    if (_expandedChapters.isEmpty && chapters.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _expandedChapters.add(chapters.first.id);
          });
        }
      });
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final isExpanded = _expandedChapters.contains(chapter.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                onTap: () => setState(() => isExpanded ? _expandedChapters.remove(chapter.id) : _expandedChapters.add(chapter.id)),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(gradient: ModernTheme.orangeGradient, borderRadius: BorderRadius.circular(12)),
                  child: Icon(isExpanded ? Iconsax.arrow_down_1 : Iconsax.arrow_right_3, color: Colors.white, size: 20),
                ),
                title: Text(chapter.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                  child: Text('${chapter.lessons.length} lessons', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
              if (isExpanded)
                ...chapter.lessons.map((lesson) {
                  final canPlay = isApproved || isFree || lesson.isFreePreview;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canPlay ? ModernTheme.primaryOrange.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(canPlay ? Iconsax.play_circle5 : Iconsax.lock, size: 20, color: canPlay ? ModernTheme.primaryOrange : Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    title: Text(lesson.title),
                    subtitle: lesson.duration != null ? Text(lesson.duration!) : null,
                    trailing: lesson.isFreePreview && !isApproved && !isFree
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: const Text('FREE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        : null,
                    onTap: canPlay ? () => context.push('/courses/${widget.courseId}/learn') : null,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutTab(Course course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this course', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (course.description != null) Text(course.description!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6)),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).colorScheme.surface, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
