class Resource {
  final String id;
  final String title;
  final String? description;
  final String type; // study_material, past_paper, project, interview_prep, article
  final String? category;
  final String? subject;
  final int? semester;
  final String? fileUrl;
  final String? externalUrl;
  final String? uploadedBy;
  final int views;
  final int downloads;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Resource({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.category,
    this.subject,
    this.semester,
    this.fileUrl,
    this.externalUrl,
    this.uploadedBy,
    this.views = 0,
    this.downloads = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Computed property for URL
  String? get url => fileUrl ?? externalUrl;
  String? get thumbnailUrl => null; // For backward compatibility

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      category: json['category'] as String?,
      subject: json['subject'] as String?,
      semester: json['semester'] as int?,
      fileUrl: json['file_url'] as String?,
      externalUrl: json['external_url'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      views: json['views'] as int? ?? 0,
      downloads: json['downloads'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'subject': subject,
      'semester': semester,
      'file_url': fileUrl,
      'external_url': externalUrl,
      'uploaded_by': uploadedBy,
      'views': views,
      'downloads': downloads,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
