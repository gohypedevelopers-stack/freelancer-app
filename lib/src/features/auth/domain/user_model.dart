class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final String? bio;
  final List<String> skills;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.status = 'ACTIVE',
    this.bio,
    this.skills = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'FREELANCER',
      status: json['status'] ?? 'ACTIVE',
      bio: json['bio'],
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'status': status,
      'bio': bio,
      'skills': skills,
    };
  }
}
