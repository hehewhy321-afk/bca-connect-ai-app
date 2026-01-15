class Announcement {
  final String id;
  final String title;
  final String content;
  final String type; // info, warning, success, error
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    required this.isActive,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String? ?? 'info',
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
