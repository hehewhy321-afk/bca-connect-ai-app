class AppConstants {
  // App Info
  static const String appName = 'BCA MMAMC';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'BCA Association MMAMC - Student Platform';

  // API Endpoints
  static const String aiChatFunction = 'ai-chat';
  static const String aiVoiceFunction = 'ai-voice';
  static const String createUserFunction = 'create-user';

  // Storage Buckets
  static const String profilesBucket = 'profiles';
  static const String eventsBucket = 'events';
  static const String resourcesBucket = 'resources';
  static const String certificatesBucket = 'certificates';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 30);
  static const Duration longCacheDuration = Duration(hours: 24);

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxBioLength = 500;
  static const int maxPostLength = 5000;
  static const int maxReplyLength = 2000;

  // Pomodoro
  static const int pomodoroWorkMinutes = 25;
  static const int pomodoroShortBreakMinutes = 5;
  static const int pomodoroLongBreakMinutes = 15;
  static const int pomodoroSessionsBeforeLongBreak = 4;

  // Notifications
  static const String notificationChannelId = 'bca_notifications';
  static const String notificationChannelName = 'BCA Notifications';
  static const String notificationChannelDescription = 'Notifications from BCA MMAMC';

  // Local Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyOfflineMode = 'offline_mode';

  // Error Messages
  static const String errorNoInternet = 'No internet connection';
  static const String errorUnauthorized = 'Unauthorized access';
  static const String errorServerError = 'Server error occurred';
  static const String errorUnknown = 'An unknown error occurred';
}

enum AppRole {
  admin,
  moderator,
  member;

  String get value => name;

  static AppRole fromString(String role) {
    return AppRole.values.firstWhere(
      (r) => r.name == role.toLowerCase(),
      orElse: () => AppRole.member,
    );
  }
}

enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled;

  String get value => name;

  static EventStatus fromString(String status) {
    return EventStatus.values.firstWhere(
      (s) => s.name == status.toLowerCase(),
      orElse: () => EventStatus.upcoming,
    );
  }
}

enum ResourceType {
  studyMaterial('study_material'),
  pastPaper('past_paper'),
  project('project'),
  interviewPrep('interview_prep'),
  article('article');

  final String value;
  const ResourceType(this.value);

  static ResourceType fromString(String type) {
    return ResourceType.values.firstWhere(
      (t) => t.value == type,
      orElse: () => ResourceType.studyMaterial,
    );
  }
}

enum NotificationType {
  info,
  event,
  forum,
  achievement,
  announcement;

  String get value => name;

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (t) => t.name == type.toLowerCase(),
      orElse: () => NotificationType.info,
    );
  }
}
