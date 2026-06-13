class UserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String? location;
  final double rating;
  final int completedTasks;
  final int pendingTasks;
  final bool verified;
  final List<SkillModel> skillsOffered;
  final List<SkillModel> skillsWanted;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.bio,
    this.location,
    this.rating = 4.0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.verified = false,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      photoUrl: json['photo_url'],
      bio: json['bio'],
      location: json['location'],
      rating: double.tryParse(json['rating']?.toString() ?? '4.0') ?? 4.0,
      completedTasks: json['completed_tasks'] ?? 0,
      pendingTasks: json['pending_tasks'] ?? 0,
      verified: json['verified'] == true || json['verified'] == 1,
      skillsOffered: (json['skills_offered'] as List<dynamic>? ?? [])
          .map((s) => SkillModel.fromJson(s))
          .toList(),
      skillsWanted: (json['skills_wanted'] as List<dynamic>? ?? [])
          .map((s) => SkillModel.fromJson(s))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'photo_url': photoUrl,
        'bio': bio,
        'location': location,
        'rating': rating,
        'completed_tasks': completedTasks,
        'pending_tasks': pendingTasks,
        'verified': verified,
      };

  bool get isProfileComplete =>
      bio != null && bio!.isNotEmpty && location != null && location!.isNotEmpty;
}

class SkillModel {
  final int id;
  final String name;
  final String? type;

  SkillModel({required this.id, required this.name, this.type});

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'],
    );
  }
}
