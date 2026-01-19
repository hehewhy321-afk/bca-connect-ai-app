class FoundingMember {
  final String id;
  final String fullName;
  final String role;
  final String? avatarUrl;
  final String? email;
  final String? phone;
  final String? linkedinUrl;
  final String? facebookUrl;
  final String? twitterUrl;
  final String? bio;
  final int displayOrder;
  final bool isActive;

  FoundingMember({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.email,
    this.phone,
    this.linkedinUrl,
    this.facebookUrl,
    this.twitterUrl,
    this.bio,
    required this.displayOrder,
    required this.isActive,
  });

  factory FoundingMember.fromJson(Map<String, dynamic> json) {
    return FoundingMember(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      facebookUrl: json['facebook_url'] as String?,
      twitterUrl: json['twitter_url'] as String?,
      bio: json['bio'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'avatar_url': avatarUrl,
      'email': email,
      'phone': phone,
      'linkedin_url': linkedinUrl,
      'facebook_url': facebookUrl,
      'twitter_url': twitterUrl,
      'bio': bio,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
