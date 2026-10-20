/// "17:00:00" -> "17:00"
String hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String todayIso() => isoDate(DateTime.now());

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

class Coach {
  const Coach({
    required this.coachId,
    required this.userId,
    required this.email,
    required this.fullName,
    this.phone,
    this.specialization,
  });

  final int coachId;
  final int userId;
  final String email;
  final String fullName;
  final String? phone;
  final String? specialization;

  factory Coach.fromJson(Map<String, dynamic> json) => Coach(
        coachId: json['coach_id'] as int,
        userId: json['user_id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        specialization: json['specialization'] as String?,
      );
}

class Registration {
  const Registration({
    required this.registrationId,
    required this.memberId,
    required this.memberName,
    required this.sportId,
    required this.sportName,
    required this.registeredAt,
  });

  final int registrationId;
  final int memberId;
  final String memberName;
  final int sportId;
  final String sportName;
  final String registeredAt;

  factory Registration.fromJson(Map<String, dynamic> json) => Registration(
        registrationId: json['registration_id'] as int,
        memberId: json['member_id'] as int,
        memberName: json['member_name'] as String,
        sportId: json['sport_id'] as int,
        sportName: json['sport_name'] as String,
        registeredAt: json['registered_at'] as String,
      );
}

/// One training session (a row of training_schedules).
class Session {
  const Session({
    required this.scheduleId,
    required this.sportId,
    required this.sportName,
    required this.iconKey,
    required this.coachId,
    required this.coachName,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.venue,
    this.notes,
  });

  final int scheduleId;
  final int sportId;
  final String sportName;
  final String iconKey;
  final int coachId;
  final String coachName;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String venue;
  final String? notes;

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        scheduleId: json['schedule_id'] as int,
        sportId: json['sport_id'] as int,
        sportName: json['sport_name'] as String,
        iconKey: json['icon_key'] as String,
        coachId: json['coach_id'] as int,
        coachName: json['coach_name'] as String,
        sessionDate: json['session_date'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        venue: json['venue'] as String,
        notes: json['notes'] as String?,
      );
}

class RosterEntry {
  const RosterEntry({
    required this.memberId,
    required this.fullName,
    this.attendanceId,
    this.status,
  });

  final int memberId;
  final String fullName;
  final int? attendanceId;
  final String? status;

  factory RosterEntry.fromJson(Map<String, dynamic> json) => RosterEntry(
        memberId: json['member_id'] as int,
        fullName: json['full_name'] as String,
        attendanceId: json['attendance_id'] as int?,
        status: json['status'] as String?,
      );
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.attendanceId,
    required this.scheduleId,
    required this.memberId,
    required this.memberName,
    required this.sportName,
    required this.sessionDate,
    required this.status,
  });

  final int attendanceId;
  final int scheduleId;
  final int memberId;
  final String memberName;
  final String sportName;
  final String sessionDate;
  final String status;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        attendanceId: json['attendance_id'] as int,
        scheduleId: json['schedule_id'] as int,
        memberId: json['member_id'] as int,
        memberName: json['member_name'] as String,
        sportName: json['sport_name'] as String,
        sessionDate: json['session_date'] as String,
        status: json['status'] as String,
      );
}