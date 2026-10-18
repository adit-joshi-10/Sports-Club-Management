/// The three roles. Unknown values fall back to member (least privilege).
enum ClubRole {
  admin,
  coach,
  member;

  static ClubRole parse(String value) => ClubRole.values
      .firstWhere((r) => r.name == value, orElse: () => ClubRole.member);
}

class AppUser {
  const AppUser({
    required this.userId,
    required this.email,
    required this.role,
    this.fullName,
  });

  final int userId;
  final String email;
  final ClubRole role;
  final String? fullName;

  String get displayName => fullName ?? email;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['user_id'] as int,
        email: json['email'] as String,
        role: ClubRole.parse(json['role'] as String),
        fullName: json['full_name'] as String?,
      );
}