class EventFeedback {
  final String id;
  final String eventId;
  final String userId;
  final int rating;
  final String? feedback;
  final bool isAnonymous;
  final DateTime createdAt;

  EventFeedback({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.rating,
    this.feedback,
    required this.isAnonymous,
    required this.createdAt,
  });

  factory EventFeedback.fromJson(Map<String, dynamic> json) {
    return EventFeedback(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      rating: json['rating'] as int,
      feedback: json['feedback'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'rating': rating,
      'feedback': feedback,
      'is_anonymous': isAnonymous,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
