class Event {
  final String id;
  final String title;
  final String? description;
  final String category;
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? imageUrl;
  final List<String> galleryImages;
  final int? maxAttendees;
  final double? registrationFee;
  final String teamType;
  final int teamSizeMin;
  final int teamSizeMax;
  final String status;
  final String visibility;
  final bool isFeatured;
  final String? adminNotes;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.startDate,
    this.endDate,
    this.location,
    this.imageUrl,
    this.galleryImages = const [],
    this.maxAttendees,
    this.registrationFee,
    this.teamType = 'solo',
    this.teamSizeMin = 1,
    this.teamSizeMax = 1,
    this.status = 'upcoming',
    this.visibility = 'public',
    this.isFeatured = false,
    this.adminNotes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      location: json['location'] as String?,
      imageUrl: json['image_url'] as String?,
      galleryImages: (json['gallery_images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      maxAttendees: json['max_attendees'] as int?,
      registrationFee: (json['registration_fee'] as num?)?.toDouble(),
      teamType: json['team_type'] as String? ?? 'solo',
      teamSizeMin: json['team_size_min'] as int? ?? 1,
      teamSizeMax: json['team_size_max'] as int? ?? 1,
      status: json['status'] as String? ?? 'upcoming',
      visibility: json['visibility'] as String? ?? 'public',
      isFeatured: json['is_featured'] as bool? ?? false,
      adminNotes: json['admin_notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'image_url': imageUrl,
      'gallery_images': galleryImages,
      'max_attendees': maxAttendees,
      'registration_fee': registrationFee,
      'team_type': teamType,
      'team_size_min': teamSizeMin,
      'team_size_max': teamSizeMax,
      'status': status,
      'visibility': visibility,
      'is_featured': isFeatured,
      'admin_notes': adminNotes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
