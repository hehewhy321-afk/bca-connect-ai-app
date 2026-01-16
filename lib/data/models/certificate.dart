import 'package:flutter/foundation.dart';

class Certificate {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? categoryId;
  final String? categoryName; // Add category name
  final String? templateId;
  final String? signatureId;
  final DateTime eventDate;
  final DateTime issueDate;
  final String verificationCode;
  final Map<String, dynamic>? certificateData;
  final String? certificateUrl; // Direct URL field
  final String? imageUrl; // Direct image URL field
  final DateTime createdAt;

  Certificate({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.categoryId,
    this.categoryName,
    this.templateId,
    this.signatureId,
    required this.eventDate,
    required this.issueDate,
    required this.verificationCode,
    this.certificateData,
    this.certificateUrl,
    this.imageUrl,
    required this.createdAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    try {
      // Extract category name from nested category object
      String? categoryName;
      if (json['category'] != null && json['category'] is Map) {
        categoryName = json['category']['name'] as String?;
      }

      return Certificate(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        categoryId: json['category_id'] as String?,
        categoryName: categoryName,
        templateId: json['template_id'] as String?,
        signatureId: json['signature_id'] as String?,
        eventDate: DateTime.parse(json['event_date'] as String),
        issueDate: json['issue_date'] != null 
            ? DateTime.parse(json['issue_date'] as String)
            : DateTime.now(),
        verificationCode: json['verification_code'] as String,
        certificateData: json['certificate_data'] as Map<String, dynamic>?,
        certificateUrl: json['certificate_url'] as String?,
        imageUrl: json['image_url'] as String?,
        createdAt: json['created_at'] != null 
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error parsing certificate: $e');
      debugPrint('   JSON: $json');
      debugPrint('   Stack: $stackTrace');
      rethrow;
    }
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
      'certificate_url': certificateUrl,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
