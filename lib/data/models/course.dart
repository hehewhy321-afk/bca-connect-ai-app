class Course {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final double price;
  final String? category;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.price,
    this.category,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'price': price,
      'category': category,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CourseChapter {
  final String id;
  final String courseId;
  final String title;
  final int orderIndex;
  final DateTime createdAt;
  final List<CourseLesson> lessons;

  CourseChapter({
    required this.id,
    required this.courseId,
    required this.title,
    required this.orderIndex,
    required this.createdAt,
    this.lessons = const [],
  });

  factory CourseChapter.fromJson(Map<String, dynamic> json) {
    return CourseChapter(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      title: json['title'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lessons: (json['lessons'] as List?)
              ?.map((e) => CourseLesson.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CourseLesson {
  final String id;
  final String chapterId;
  final String title;
  final String? videoUrl;
  final String? duration;
  final bool isFreePreview;
  final int orderIndex;
  final DateTime createdAt;

  CourseLesson({
    required this.id,
    required this.chapterId,
    required this.title,
    this.videoUrl,
    this.duration,
    required this.isFreePreview,
    required this.orderIndex,
    required this.createdAt,
  });

  factory CourseLesson.fromJson(Map<String, dynamic> json) {
    return CourseLesson(
      id: json['id'] as String,
      chapterId: json['chapter_id'] as String,
      title: json['title'] as String,
      videoUrl: json['video_url'] as String?,
      duration: json['duration'] as String?,
      isFreePreview: json['is_free_preview'] as bool? ?? false,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

enum EnrollmentStatus {
  pending,
  approved,
  rejected;

  String get value {
    switch (this) {
      case EnrollmentStatus.pending:
        return 'pending';
      case EnrollmentStatus.approved:
        return 'approved';
      case EnrollmentStatus.rejected:
        return 'rejected';
    }
  }

  static EnrollmentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return EnrollmentStatus.approved;
      case 'rejected':
        return EnrollmentStatus.rejected;
      default:
        return EnrollmentStatus.pending;
    }
  }
}

class CourseEnrollment {
  final String id;
  final String userId;
  final String courseId;
  final EnrollmentStatus status;
  final String? paymentScreenshotUrl;
  final String? transactionId;
  final DateTime enrolledAt;
  final DateTime updatedAt;

  CourseEnrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.status,
    this.paymentScreenshotUrl,
    this.transactionId,
    required this.enrolledAt,
    required this.updatedAt,
  });

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) {
    return CourseEnrollment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      courseId: json['course_id'] as String,
      status: EnrollmentStatus.fromString(json['status'] as String),
      paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
      transactionId: json['transaction_id'] as String?,
      enrolledAt: DateTime.parse(json['enrolled_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
