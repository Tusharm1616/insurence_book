class UserProfile {
  final int id;
  final String username;
  final String fullName;
  final String role;
  final String? email;

  UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
    this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      role: json['role'],
      email: json['email'],
    );
  }
}
