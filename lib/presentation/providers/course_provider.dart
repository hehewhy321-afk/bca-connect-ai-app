import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/course.dart';
import '../../data/repositories/course_repository.dart';
import 'auth_provider.dart';

final courseRepositoryProvider = Provider((ref) => CourseRepository());

// Published courses provider
final publishedCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getPublishedCourses();
});

// Single course provider
final courseDetailProvider = FutureProvider.family<Course, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseById(courseId);
});

// Course chapters provider
final courseChaptersProvider = FutureProvider.family<List<CourseChapter>, String>((ref, courseId) async {
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getCourseChapters(courseId);
});

// User enrollments provider
final userEnrollmentsProvider = FutureProvider<List<CourseEnrollment>>((ref) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return [];
  
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getUserEnrollments(user.id);
});

// Single enrollment status provider
final enrollmentStatusProvider = FutureProvider.family<CourseEnrollment?, String>((ref, courseId) async {
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return null;
  
  final repository = ref.watch(courseRepositoryProvider);
  return repository.getUserEnrollment(user.id, courseId);
});
