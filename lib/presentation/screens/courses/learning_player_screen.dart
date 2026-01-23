import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../data/models/course.dart';
import '../../../core/theme/modern_theme.dart';
import '../../providers/course_provider.dart';

// Provider for current lesson - persists across rebuilds
final currentLessonIndexProvider = StateProvider.family<int, String>((ref, courseId) => 0);

class LearningPlayerScreen extends ConsumerStatefulWidget {
  final String courseId;

  const LearningPlayerScreen({super.key, required this.courseId});

  @override
  ConsumerState<LearningPlayerScreen> createState() => _LearningPlayerScreenState();
}

class _LearningPlayerScreenState extends ConsumerState<LearningPlayerScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  final Set<String> _expandedChapters = {}; // Track expanded chapters

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _initializePlayer(String videoUrl) {
    setState(() => _isLoading = true);
    
    // Create HTML with iframe to embed Abyss video
    final html = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
          }
          html, body {
            width: 100%;
            height: 100%;
            background: #000;
            overflow: hidden;
          }
          iframe {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            border: none;
          }
        </style>
      </head>
      <body>
        <iframe 
          src="$videoUrl" 
          frameborder="0" 
          allowfullscreen 
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen"
          webkitallowfullscreen 
          mozallowfullscreen
        ></iframe>
      </body>
      </html>
    ''';
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // Prevent opening external browser
            // Only allow the initial load and iframe content
            if (request.url.startsWith('data:') || 
                request.url.startsWith('about:') ||
                request.url.contains('short.ink') ||
                request.url.contains('abyss')) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: 'https://short.ink');
  }

  void _switchLesson(int newIndex, List<CourseLesson> allLessons, bool isApproved, bool isFree) {
    final lesson = allLessons[newIndex];
    final canPlay = isApproved || isFree || lesson.isFreePreview;
    
    if (canPlay && lesson.videoUrl != null) {
      ref.read(currentLessonIndexProvider(widget.courseId).notifier).state = newIndex;
      _initializePlayer(lesson.videoUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final chaptersAsync = ref.watch(courseChaptersProvider(widget.courseId));
    final enrollmentAsync = ref.watch(enrollmentStatusProvider(widget.courseId));
    final currentLessonIndex = ref.watch(currentLessonIndexProvider(widget.courseId));

    return courseAsync.when(
      data: (course) {
        final enrollment = enrollmentAsync.value;
        final isApproved = enrollment?.status == EnrollmentStatus.approved;
        final isFree = course.price == 0;

        return chaptersAsync.when(
          data: (chapters) {
            final allLessons = chapters.expand((c) => c.lessons).toList();

            if (allLessons.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(course.title)),
                body: const Center(child: Text('No lessons available')),
              );
            }

            final validIndex = currentLessonIndex.clamp(0, allLessons.length - 1);
            final currentLesson = allLessons[validIndex];
            final canPlay = isApproved || isFree || currentLesson.isFreePreview;

            // Initialize player on first build
            if (_webViewController == null && canPlay && currentLesson.videoUrl != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializePlayer(currentLesson.videoUrl!);
              });
            }

            // Normal Mode
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(course.title, style: const TextStyle(fontSize: 16)),
                elevation: 0,
              ),
              body: Column(
                children: [
                  // Video Player Section
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.black,
                          child: canPlay && _webViewController != null
                              ? WebViewWidget(controller: _webViewController!)
                              : _buildLockedOverlay(context),
                        ),
                        // Loading Indicator
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(color: ModernTheme.primaryOrange),
                          ),
                      ],
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          // Progress Bar
                          LinearProgressIndicator(
                            value: (validIndex + 1) / allLessons.length,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(ModernTheme.primaryOrange),
                            minHeight: 3,
                          ),

                          // Lesson Info Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentLesson.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: ModernTheme.primaryOrange.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Lesson ${validIndex + 1}/${allLessons.length}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: ModernTheme.primaryOrange,
                                                  ),
                                                ),
                                              ),
                                              if (currentLesson.duration != null) ...[
                                                const SizedBox(width: 8),
                                                Icon(Iconsax.clock, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                const SizedBox(width: 4),
                                                Text(currentLesson.duration!, style: Theme.of(context).textTheme.bodySmall),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Course Progress Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                      child: Text(
                                        '${((validIndex + 1) / allLessons.length * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Navigation Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: validIndex > 0
                                            ? () => _switchLesson(validIndex - 1, allLessons, isApproved, isFree)
                                            : null,
                                        icon: const Icon(Iconsax.arrow_left_2, size: 18),
                                        label: const Text('Previous'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: validIndex < allLessons.length - 1
                                            ? () => _switchLesson(validIndex + 1, allLessons, isApproved, isFree)
                                            : null,
                                        icon: const Icon(Iconsax.arrow_right_3, size: 18),
                                        label: const Text('Next'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Always Show Lessons List
                          Expanded(
                            child: _buildLessonsList(chapters, validIndex, allLessons, isApproved, isFree),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: Text(course.title)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            appBar: AppBar(title: Text(course.title)),
            body: Center(child: Text('Error: $error')),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildLockedOverlay(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.lock, size: 48, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'This lesson is locked',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enroll in this course to unlock',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Iconsax.arrow_left),
              label: const Text('Back to Course'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(
    List<CourseChapter> chapters,
    int currentIndex,
    List<CourseLesson> allLessons,
    bool isApproved,
    bool isFree,
  ) {
    if (_expandedChapters.isEmpty) {
      for (var chapter in chapters) {
        for (var lesson in chapter.lessons) {
          if (allLessons.indexOf(lesson) == currentIndex) {
            _expandedChapters.add(chapter.id);
            break;
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chapters.length,
        itemBuilder: (context, chapterIndex) {
          final chapter = chapters[chapterIndex];
          return _ChapterItem(
            chapter: chapter,
            allLessons: allLessons,
            currentIndex: currentIndex,
            isExpanded: _expandedChapters.contains(chapter.id),
            isApproved: isApproved,
            isFree: isFree,
            onToggle: () {
              setState(() {
                if (_expandedChapters.contains(chapter.id)) {
                  _expandedChapters.remove(chapter.id);
                } else {
                  _expandedChapters.add(chapter.id);
                }
              });
            },
            onLessonTap: (lessonIndex) => _switchLesson(lessonIndex, allLessons, isApproved, isFree),
          );
        },
      ),
    );
  }
}

class _ChapterItem extends StatelessWidget {
  final CourseChapter chapter;
  final List<CourseLesson> allLessons;
  final int currentIndex;
  final bool isExpanded;
  final bool isApproved;
  final bool isFree;
  final VoidCallback onToggle;
  final void Function(int) onLessonTap;

  const _ChapterItem({
    required this.chapter,
    required this.allLessons,
    required this.currentIndex,
    required this.isExpanded,
    required this.isApproved,
    required this.isFree,
    required this.onToggle,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedLessons = chapter.lessons.where((lesson) {
      final idx = allLessons.indexOf(lesson);
      return idx < currentIndex;
    }).length;
    final progress = chapter.lessons.isEmpty ? 0.0 : completedLessons / chapter.lessons.length;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isExpanded 
                ? ModernTheme.primaryOrange.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
              blurRadius: isExpanded ? 15 : 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isExpanded 
              ? ModernTheme.primaryOrange.withValues(alpha: 0.2)
              : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildChapterIcon(context),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChapterInfo(context, progress)),
                    _buildExpandIcon(context),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Column(
                      children: chapter.lessons.map((lesson) {
                        final lessonIndex = allLessons.indexOf(lesson);
                        final canPlay = isApproved || isFree || lesson.isFreePreview;
                        final isCurrentLesson = lessonIndex == currentIndex;
                        final isCompleted = lessonIndex < currentIndex;

                        return _LessonItem(
                          lesson: lesson,
                          canPlay: canPlay,
                          isCurrentLesson: isCurrentLesson,
                          isCompleted: isCompleted,
                          isApproved: isApproved,
                          isFree: isFree,
                          onTap: canPlay ? () => onLessonTap(lessonIndex) : null,
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterIcon(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isExpanded 
          ? ModernTheme.orangeGradient
          : LinearGradient(
              colors: [
                ModernTheme.primaryOrange.withValues(alpha: 0.2),
                ModernTheme.primaryOrange.withValues(alpha: 0.1),
              ],
            ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Icon(
        Iconsax.video_square5,
        size: 24,
        color: isExpanded ? Colors.white : ModernTheme.primaryOrange,
      ),
    );
  }

  Widget _buildChapterInfo(BuildContext context, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chapter.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isExpanded ? ModernTheme.primaryOrange : null,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Iconsax.play_circle,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${chapter.lessons.length} lessons',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (progress > 0) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpandIcon(BuildContext context) {
    return AnimatedRotation(
      turns: isExpanded ? 0.5 : 0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isExpanded 
            ? ModernTheme.primaryOrange.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Iconsax.arrow_down_1,
          size: 20,
          color: isExpanded 
            ? ModernTheme.primaryOrange 
            : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  final CourseLesson lesson;
  final bool canPlay;
  final bool isCurrentLesson;
  final bool isCompleted;
  final bool isApproved;
  final bool isFree;
  final VoidCallback? onTap;

  const _LessonItem({
    required this.lesson,
    required this.canPlay,
    required this.isCurrentLesson,
    required this.isCompleted,
    required this.isApproved,
    required this.isFree,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrentLesson
              ? ModernTheme.primaryOrange.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentLesson
                ? ModernTheme.primaryOrange.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildLeadingIcon(context),
          title: Text(
            lesson.title,
            style: TextStyle(
              fontWeight: isCurrentLesson ? FontWeight.bold : FontWeight.w500,
              color: isCurrentLesson ? ModernTheme.primaryOrange : null,
              fontSize: 14,
            ),
          ),
          subtitle: lesson.duration != null ? _buildDuration(context) : null,
          trailing: _buildTrailing(),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: isCurrentLesson
            ? ModernTheme.orangeGradient
            : isCompleted
                ? LinearGradient(
                    colors: [
                      Colors.green.withValues(alpha: 0.2),
                      Colors.green.withValues(alpha: 0.1),
                    ],
                  )
                : canPlay
                    ? LinearGradient(
                        colors: [
                          ModernTheme.primaryOrange.withValues(alpha: 0.2),
                          ModernTheme.primaryOrange.withValues(alpha: 0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                        ],
                      ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isCurrentLesson
            ? [
                BoxShadow(
                  color: ModernTheme.primaryOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Icon(
        isCompleted
            ? Iconsax.tick_circle5
            : canPlay
                ? Iconsax.play5
                : Iconsax.lock_1,
        size: 20,
        color: isCurrentLesson
            ? Colors.white
            : isCompleted
                ? Colors.green
                : canPlay
                    ? ModernTheme.primaryOrange
                    : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildDuration(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Iconsax.clock,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            lesson.duration!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTrailing() {
    if (lesson.isFreePreview && !isApproved && !isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withValues(alpha: 0.2),
              Colors.green.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Text(
          'FREE',
          style: TextStyle(
            color: Colors.green,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    
    if (isCurrentLesson) {
      return Container(
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          gradient: ModernTheme.orangeGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Iconsax.music_play5,
          size: 16,
          color: Colors.white,
        ),
      );
    }
    
    return null;
  }
}
