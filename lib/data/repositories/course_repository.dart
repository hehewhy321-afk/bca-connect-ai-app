import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';

class CourseRepository {
  final _supabase = Supabase.instance.client;
  final _connectivity = ConnectivityService();

  // Fetch all published courses with caching
  Future<List<Course>> getPublishedCourses({bool forceRefresh = false}) async {
    const cacheKey = '${CacheKeys.courses}_published';
    
    // Check connectivity first
    final isOnline = await _connectivity.isOnline();
    
    // If online and not forcing refresh, try cache first for better performance
    if (isOnline && !forceRefresh) {
      try {
        final cached = CacheService.get<String>(cacheKey);
        if (cached != null) {
          final List<dynamic> jsonList = jsonDecode(cached);
          final courses = jsonList.map((e) => Course.fromJson(e)).toList();
          debugPrint('Loaded ${courses.length} courses from cache (fast load)');
          
          // Fetch fresh data in background and update cache
          _fetchAndCacheCoursesInBackground(cacheKey);
          
          return courses;
        }
      } catch (e) {
        debugPrint('Error loading courses from cache: $e');
      }
    }
    
    // If online, fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('courses')
            .select()
            .eq('is_published', true)
            .order('created_at', ascending: false);

        final courses = (response as List)
            .map((json) => Course.fromJson(json))
            .toList();
        
        debugPrint('Fetched ${courses.length} courses from database (online)');
        
        // Cache the fresh results
        final jsonList = courses.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.mediumCache,
        );
        
        return courses;
      } catch (e) {
        debugPrint('Error fetching courses: $e');
        // Fall through to cache on error
      }
    }
    
    // If offline or error, use cache
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final courses = jsonList.map((e) => Course.fromJson(e)).toList();
        debugPrint('Loaded ${courses.length} courses from cache (offline or error)');
        return courses;
      }
    } catch (e) {
      debugPrint('Error loading courses from cache: $e');
    }
    
    throw Exception('No internet connection and no cached courses available');
  }

  // Background fetch to update cache
  Future<void> _fetchAndCacheCoursesInBackground(String cacheKey) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final courses = (response as List)
          .map((json) => Course.fromJson(json))
          .toList();
      
      // Update cache with fresh data
      final jsonList = courses.map((e) => e.toJson()).toList();
      await CacheService.set(
        cacheKey,
        jsonEncode(jsonList),
        duration: CacheKeys.mediumCache,
      );
      
      debugPrint('Background updated cache with ${courses.length} courses');
    } catch (e) {
      debugPrint('Background course fetch failed: $e');
    }
  }

  // Fetch course by ID with caching
  Future<Course> getCourseById(String courseId) async {
    final cacheKey = '${CacheKeys.courses}_$courseId';
    
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    // Try cache first for better performance
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final course = Course.fromJson(jsonDecode(cached));
        debugPrint('Loaded course $courseId from cache');
        
        // If online, update cache in background
        if (isOnline) {
          _fetchAndCacheCourseInBackground(courseId, cacheKey);
        }
        
        return course;
      }
    } catch (e) {
      debugPrint('Error loading course from cache: $e');
    }
    
    // If online, fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('courses')
            .select()
            .eq('id', courseId)
            .single();

        final course = Course.fromJson(response);
        
        // Cache the result
        await CacheService.set(
          cacheKey,
          jsonEncode(course.toJson()),
          duration: CacheKeys.mediumCache,
        );
        
        debugPrint('Fetched course $courseId from database');
        return course;
      } catch (e) {
        debugPrint('Error fetching course: $e');
        throw Exception('Unable to load course. Please check your connection.');
      }
    }
    
    throw Exception('No internet connection and course not cached');
  }

  // Background fetch for single course
  Future<void> _fetchAndCacheCourseInBackground(String courseId, String cacheKey) async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      final course = Course.fromJson(response);
      
      // Update cache
      await CacheService.set(
        cacheKey,
        jsonEncode(course.toJson()),
        duration: CacheKeys.mediumCache,
      );
      
      debugPrint('Background updated cache for course $courseId');
    } catch (e) {
      debugPrint('Background course fetch failed for $courseId: $e');
    }
  }

  // Fetch chapters with lessons for a course with caching
  Future<List<CourseChapter>> getCourseChapters(String courseId) async {
    final cacheKey = '${CacheKeys.courses}_chapters_$courseId';
    
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    // Try cache first
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final chapters = jsonList.map((e) => CourseChapter.fromJson(e)).toList();
        debugPrint('Loaded ${chapters.length} chapters from cache for course $courseId');
        
        // If online, update cache in background
        if (isOnline) {
          _fetchAndCacheChaptersInBackground(courseId, cacheKey);
        }
        
        return chapters;
      }
    } catch (e) {
      debugPrint('Error loading chapters from cache: $e');
    }
    
    // If online, fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('course_chapters')
            .select('*, lessons:course_lessons(*)')
            .eq('course_id', courseId)
            .order('order_index', ascending: true);

        final chapters = (response as List).map((json) {
          // Sort lessons by order_index in ascending order
          if (json['lessons'] != null) {
            (json['lessons'] as List).sort((a, b) =>
                (a['order_index'] as int).compareTo(b['order_index'] as int));
          }
          return CourseChapter.fromJson(json);
        }).toList();
        
        // Cache the result
        final jsonList = chapters.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.mediumCache,
        );
        
        debugPrint('Fetched ${chapters.length} chapters from database for course $courseId');
        return chapters;
      } catch (e) {
        debugPrint('Error fetching chapters: $e');
        throw Exception('Unable to load course content. Please check your connection.');
      }
    }
    
    throw Exception('No internet connection and course content not cached');
  }

  // Background fetch for chapters
  Future<void> _fetchAndCacheChaptersInBackground(String courseId, String cacheKey) async {
    try {
      final response = await _supabase
          .from('course_chapters')
          .select('*, lessons:course_lessons(*)')
          .eq('course_id', courseId)
          .order('order_index', ascending: true);

      final chapters = (response as List).map((json) {
        if (json['lessons'] != null) {
          (json['lessons'] as List).sort((a, b) =>
              (a['order_index'] as int).compareTo(b['order_index'] as int));
        }
        return CourseChapter.fromJson(json);
      }).toList();
      
      // Update cache
      final jsonList = chapters.map((e) => e.toJson()).toList();
      await CacheService.set(
        cacheKey,
        jsonEncode(jsonList),
        duration: CacheKeys.mediumCache,
      );
      
      debugPrint('Background updated cache for chapters of course $courseId');
    } catch (e) {
      debugPrint('Background chapters fetch failed for $courseId: $e');
    }
  }

  // Check user enrollment status with caching
  Future<CourseEnrollment?> getUserEnrollment(String userId, String courseId) async {
    final cacheKey = '${CacheKeys.courses}_enrollment_${userId}_$courseId';
    
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    // Try cache first
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final enrollment = CourseEnrollment.fromJson(jsonDecode(cached));
        debugPrint('Loaded enrollment from cache for user $userId, course $courseId');
        
        // If online, update cache in background
        if (isOnline) {
          _fetchAndCacheEnrollmentInBackground(userId, courseId, cacheKey);
        }
        
        return enrollment;
      }
    } catch (e) {
      debugPrint('Error loading enrollment from cache: $e');
    }
    
    // If online, fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('course_enrollments')
            .select()
            .eq('user_id', userId)
            .eq('course_id', courseId)
            .maybeSingle();

        if (response == null) return null;
        
        final enrollment = CourseEnrollment.fromJson(response);
        
        // Cache the result
        await CacheService.set(
          cacheKey,
          jsonEncode(enrollment.toJson()),
          duration: CacheKeys.shortCache, // Enrollment status changes more frequently
        );
        
        return enrollment;
      } catch (e) {
        debugPrint('Error checking enrollment: $e');
        throw Exception('Unable to check enrollment status. Please check your connection.');
      }
    }
    
    // If offline, return null (assume not enrolled)
    return null;
  }

  // Background fetch for enrollment
  Future<void> _fetchAndCacheEnrollmentInBackground(String userId, String courseId, String cacheKey) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select()
          .eq('user_id', userId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (response != null) {
        final enrollment = CourseEnrollment.fromJson(response);
        
        // Update cache
        await CacheService.set(
          cacheKey,
          jsonEncode(enrollment.toJson()),
          duration: CacheKeys.shortCache,
        );
        
        debugPrint('Background updated enrollment cache for user $userId, course $courseId');
      }
    } catch (e) {
      debugPrint('Background enrollment fetch failed: $e');
    }
  }

  // Get all user enrollments with caching
  Future<List<CourseEnrollment>> getUserEnrollments(String userId) async {
    final cacheKey = '${CacheKeys.courses}_enrollments_$userId';
    
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    // Try cache first
    try {
      final cached = CacheService.get<String>(cacheKey);
      if (cached != null) {
        final List<dynamic> jsonList = jsonDecode(cached);
        final enrollments = jsonList.map((e) => CourseEnrollment.fromJson(e)).toList();
        debugPrint('Loaded ${enrollments.length} enrollments from cache for user $userId');
        
        // If online, update cache in background
        if (isOnline) {
          _fetchAndCacheEnrollmentsInBackground(userId, cacheKey);
        }
        
        return enrollments;
      }
    } catch (e) {
      debugPrint('Error loading enrollments from cache: $e');
    }
    
    // If online, fetch fresh data
    if (isOnline) {
      try {
        final response = await _supabase
            .from('course_enrollments')
            .select()
            .eq('user_id', userId);

        final enrollments = (response as List)
            .map((json) => CourseEnrollment.fromJson(json))
            .toList();
        
        // Cache the result
        final jsonList = enrollments.map((e) => e.toJson()).toList();
        await CacheService.set(
          cacheKey,
          jsonEncode(jsonList),
          duration: CacheKeys.shortCache,
        );
        
        debugPrint('Fetched ${enrollments.length} enrollments from database for user $userId');
        return enrollments;
      } catch (e) {
        debugPrint('Error fetching enrollments: $e');
        throw Exception('Unable to load enrollments. Please check your connection.');
      }
    }
    
    // If offline, return empty list
    return [];
  }

  // Background fetch for enrollments
  Future<void> _fetchAndCacheEnrollmentsInBackground(String userId, String cacheKey) async {
    try {
      final response = await _supabase
          .from('course_enrollments')
          .select()
          .eq('user_id', userId);

      final enrollments = (response as List)
          .map((json) => CourseEnrollment.fromJson(json))
          .toList();
      
      // Update cache
      final jsonList = enrollments.map((e) => e.toJson()).toList();
      await CacheService.set(
        cacheKey,
        jsonEncode(jsonList),
        duration: CacheKeys.shortCache,
      );
      
      debugPrint('Background updated enrollments cache for user $userId');
    } catch (e) {
      debugPrint('Background enrollments fetch failed for user $userId: $e');
    }
  }

  // Enroll in a course
  Future<void> enrollInCourse({
    required String userId,
    required String courseId,
    String? paymentScreenshotUrl,
    String? transactionId,
  }) async {
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    if (!isOnline) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
    try {
      await _supabase.from('course_enrollments').insert({
        'user_id': userId,
        'course_id': courseId,
        'payment_screenshot_url': paymentScreenshotUrl,
        'transaction_id': transactionId,
        'status': 'pending',
      });
      
      // Clear enrollment caches to force refresh
      final enrollmentCacheKey = '${CacheKeys.courses}_enrollment_${userId}_$courseId';
      final enrollmentsCacheKey = '${CacheKeys.courses}_enrollments_$userId';
      CacheService.clearCache(enrollmentCacheKey);
      CacheService.clearCache(enrollmentsCacheKey);
      
    } catch (e) {
      debugPrint('Error enrolling in course: $e');
      if (e.toString().contains('duplicate')) {
        throw Exception('You are already enrolled in this course.');
      } else if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else {
        throw Exception('Unable to enroll in course. Please try again later.');
      }
    }
  }

  // Upload payment screenshot
  Future<String> uploadPaymentScreenshot(String userId, String filePath) async {
    // Check connectivity
    final isOnline = await _connectivity.isOnline();
    
    if (!isOnline) {
      throw Exception('No internet connection. Please check your network and try again.');
    }
    
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
      debugPrint('Error uploading payment screenshot: $e');
      if (e.toString().contains('network') || e.toString().contains('timeout')) {
        throw Exception('Upload failed due to network issues. Please try again.');
      } else if (e.toString().contains('size') || e.toString().contains('large')) {
        throw Exception('File is too large. Please choose a smaller image.');
      } else {
        throw Exception('Unable to upload screenshot. Please try again.');
      }
    }
  }
}
