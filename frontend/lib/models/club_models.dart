class Sport {
  const Sport({
    required this.sportId,
    required this.name,
    this.description,
    required this.iconKey,
  });

  final int sportId;
  final String name;
  final String? description;
  final String iconKey;

  factory Sport.fromJson(Map<String, dynamic> json) => Sport(
        sportId: json['sport_id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        iconKey: json['icon_key'] as String,
      );
}

class Member {
  const Member({
    required this.memberId,
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    required this.joinedOn,
  });

  final int memberId;
  final int userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? dateOfBirth;
  final String joinedOn;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        memberId: json['member_id'] as int,
        userId: json['user_id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        dateOfBirth: json['date_of_birth'] as String?,
        joinedOn: json['joined_on'] as String,
      );
}