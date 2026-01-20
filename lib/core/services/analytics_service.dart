import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  // Log screen views
  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenName,
      );
      debugPrint('Analytics: Screen view logged - $screenName');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Log custom events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Analytics: Event logged - $name');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Log login
  Future<void> logLogin(String method) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  // Log sign up
  Future<void> logSignUp(String method) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method},
    );
  }

  // Log feature usage
  Future<void> logFeatureUsage(String featureName) async {
    await logEvent(
      name: 'feature_used',
      parameters: {'feature_name': featureName},
    );
  }

  // Log AI chat
  Future<void> logAIChat({required String mode, required String provider}) async {
    await logEvent(
      name: 'ai_chat',
      parameters: {
        'mode': mode,
        'provider': provider,
      },
    );
  }

  // Log event registration
  Future<void> logEventRegistration(String eventId, String eventName) async {
    await logEvent(
      name: 'event_registration',
      parameters: {
        'event_id': eventId,
        'event_name': eventName,
      },
    );
  }

  // Log resource download
  Future<void> logResourceDownload(String resourceId, String resourceName) async {
    await logEvent(
      name: 'resource_download',
      parameters: {
        'resource_id': resourceId,
        'resource_name': resourceName,
      },
    );
  }

  // Log forum post creation
  Future<void> logForumPost(String category) async {
    await logEvent(
      name: 'forum_post_created',
      parameters: {'category': category},
    );
  }

  // Log certificate generation
  Future<void> logCertificateGenerated(String certificateType) async {
    await logEvent(
      name: 'certificate_generated',
      parameters: {'type': certificateType},
    );
  }

  // Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint('Analytics: User property set - $name: $value');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('Analytics: User ID set - $userId');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  // Reset analytics data (on logout)
  Future<void> resetAnalyticsData() async {
    try {
      await _analytics.setUserId(id: null);
      debugPrint('Analytics: User data reset');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }
}
