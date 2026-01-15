class Certificate {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final String? templateId;
  final String? signatureId;
  final DateTime eventDate;
  final DateTime issueDate;
  final String verificationCode;
  final Map<String, dynamic>? certificateData;
  final DateTime createdAt;

  Certificate({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    this.templateId,
    this.signatureId,
    required this.eventDate,
    required this.issueDate,
    required this.verificationCode,
    this.certificateData,
    required this.createdAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String?,
      templateId: json['template_id'] as String?,
      signatureId: json['signature_id'] as String?,
      eventDate: DateTime.parse(json['event_date'] as String),
      issueDate: json['issue_date'] != null 
          ? DateTime.parse(json['issue_date'] as String)
          : DateTime.now(),
      verificationCode: json['verification_code'] as String,
      certificateData: json['certificate_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'template_id': templateId,
      'signature_id': signatureId,
      'event_date': eventDate.toIso8601String(),
      'issue_date': issueDate.toIso8601String(),
      'verification_code': verificationCode,
      'certificate_data': certificateData,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
