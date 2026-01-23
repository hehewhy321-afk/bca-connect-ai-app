import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

class CourseRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all published courses
  Future<List<Course>> getPublishedCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Course.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  // Fetch course by ID
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      return Course.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch course: $e');
    }
  }

  // Fetch chapters with lessons for a course
  Future<List<CourseChapter>> getCourseChapters(String courseId) async {
    try {
      final response = await _supabase
          .from('course_chapters')
          .select('*, lessons:course_lessons(*)')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      return (response as List).map((json) {
        // Sort lessons by order_index in ascending order
        if (json['lessons'] != null) {
          (json['lessons'] as List).sort((a, b) =>
              (a['order_index'] as int).compareTo(b['order_index'] as int));
        }
        return CourseChapter.fromJson(json);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch chapters: $e');
    }
  }

  // Check user enrollment status
  Future<CourseEnrollment?> getUserEnrollment(
      String userId, String courseId) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (response == null) return null;
      return CourseEnrollment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to check enrollment: $e');
    }
  }

  // Get all user enrollments
  Future<List<CourseEnrollment>> getUserEnrollments(String userId) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select()
          .eq('user_id', userId);

      return (response as List)
          .map((json) => CourseEnrollment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch enrollments: $e');
    }
  }

  // Enroll in a course
  Future<void> enrollInCourse({
    required String userId,
    required String courseId,
    String? paymentScreenshotUrl,
    String? transactionId,
  }) async {
    try {
      await _supabase.from('course_enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
        'payment_screenshot_url': paymentScreenshotUrl,
        'transaction_id': transactionId,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to enroll: $e');
    }
  }

  // Upload payment screenshot
  Future<String> uploadPaymentScreenshot(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final fileName = 'payment_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'payments/$fileName';

      await _supabase.storage.from('resources').upload(
            storagePath,
            file,
          );

      final publicUrl = _supabase.storage.from('resources').getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload screenshot: $e');
    }
  }
}
