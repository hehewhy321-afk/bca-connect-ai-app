class UserProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String? phone;
  final String? bio;
  final String? batch;
  final int? semester;
  final bool isAlumni;
  final int? graduationYear;
  final String? currentCompany;
  final String? jobTitle;
  final List<String> skills;
  final String? linkedinUrl;
  final String? githubUrl;
  final int xpPoints;
  final int level;
  final bool isBanned;
  final DateTime? banExpiresAt;
  final String? banReason;
  final Map<String, dynamic> notificationPreferences;
  final bool pushNotificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.batch,
    this.semester,
    this.isAlumni = false,
    this.graduationYear,
    this.currentCompany,
    this.jobTitle,
    this.skills = const [],
    this.linkedinUrl,
    this.githubUrl,
    this.xpPoints = 0,
    this.level = 1,
    this.isBanned = false,
    this.banExpiresAt,
    this.banReason,
    this.notificationPreferences = const {},
    this.pushNotificationsEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      bio: json['bio'] as String?,
      batch: json['batch'] as String?,
      semester: json['semester'] as int?,
      isAlumni: json['is_alumni'] as bool? ?? false,
      graduationYear: json['graduation_year'] as int?,
      currentCompany: json['current_company'] as String?,
      jobTitle: json['job_title'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      linkedinUrl: json['linkedin_url'] as String?,
      githubUrl: json['github_url'] as String?,
      xpPoints: json['xp_points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      isBanned: json['is_banned'] as bool? ?? false,
      banExpiresAt: json['ban_expires_at'] != null ? DateTime.parse(json['ban_expires_at'] as String) : null,
      banReason: json['ban_reason'] as String?,
      notificationPreferences: json['notification_preferences'] as Map<String, dynamic>? ?? {},
      pushNotificationsEnabled: json['push_notifications_enabled'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'phone': phone,
      'bio': bio,
      'batch': batch,
      'semester': semester,
      'is_alumni': isAlumni,
      'graduation_year': graduationYear,
      'current_company': currentCompany,
      'job_title': jobTitle,
      'skills': skills,
      'linkedin_url': linkedinUrl,
      'github_url': githubUrl,
      'xp_points': xpPoints,
      'level': level,
      'is_banned': isBanned,
      'ban_expires_at': banExpiresAt?.toIso8601String(),
      'ban_reason': banReason,
      'notification_preferences': notificationPreferences,
      'push_notifications_enabled': pushNotificationsEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
