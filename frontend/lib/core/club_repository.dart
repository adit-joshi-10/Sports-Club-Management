import '../models/club_models.dart';
import 'api_client.dart';

/// All club data calls live here, so screens never build URLs themselves.
class ClubRepository {
  ClubRepository(this.api);

  final ApiClient api;

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, String>? query,
  }) async {
    final data = await api.get(path, query: query) as List<dynamic>;
    return data.map((e) => parse(e as Map<String, dynamic>)).toList();
  }

  // ---- sports
  Future<List<Sport>> sports() => _list('/sports', Sport.fromJson);

  Future<Sport> createSport(Map<String, dynamic> body) async =>
      Sport.fromJson(await api.post('/sports', body: body) as Map<String, dynamic>);

  Future<Sport> updateSport(int id, Map<String, dynamic> body) async =>
      Sport.fromJson(await api.patch('/sports/$id', body: body) as Map<String, dynamic>);

  Future<void> deleteSport(int id) => api.delete('/sports/$id');

  // ---- members
  Future<Member> myProfile() async =>
      Member.fromJson(await api.get('/members/me') as Map<String, dynamic>);

  Future<List<Member>> members({String? search}) {
    final q = search?.trim() ?? '';
    return _list('/members', Member.fromJson, query: q.isEmpty ? null : {'search': q});
  }

  Future<Member> createMember(Map<String, dynamic> body) async =>
      Member.fromJson(await api.post('/members', body: body) as Map<String, dynamic>);

  Future<Member> updateMember(int id, Map<String, dynamic> body) async =>
      Member.fromJson(await api.patch('/members/$id', body: body) as Map<String, dynamic>);

  Future<void> deleteMember(int id) => api.delete('/members/$id');

  // ---- coaches
  Future<List<Coach>> coaches({String? search}) {
    final q = search?.trim() ?? '';
    return _list('/coaches', Coach.fromJson, query: q.isEmpty ? null : {'search': q});
  }

  Future<Coach> createCoach(Map<String, dynamic> body) async =>
      Coach.fromJson(await api.post('/coaches', body: body) as Map<String, dynamic>);

  Future<Coach> updateCoach(int id, Map<String, dynamic> body) async =>
      Coach.fromJson(await api.patch('/coaches/$id', body: body) as Map<String, dynamic>);

  Future<void> deleteCoach(int id) => api.delete('/coaches/$id');

  // ---- registrations
  Future<List<Registration>> myRegistrations() =>
      _list('/registrations/me', Registration.fromJson);

  Future<List<Registration>> allRegistrations() =>
      _list('/registrations', Registration.fromJson);

  Future<Registration> register(int sportId) async => Registration.fromJson(
      await api.post('/registrations', body: {'sport_id': sportId})
          as Map<String, dynamic>);

  Future<void> cancelRegistration(int id) => api.delete('/registrations/$id');

  // ---- sessions (training schedules)
  Future<List<Session>> sessions() => _list('/schedules', Session.fromJson);

  Future<Session> createSession(Map<String, dynamic> body) async =>
      Session.fromJson(await api.post('/schedules', body: body) as Map<String, dynamic>);

  Future<Session> updateSession(int id, Map<String, dynamic> body) async =>
      Session.fromJson(await api.patch('/schedules/$id', body: body) as Map<String, dynamic>);

  Future<void> deleteSession(int id) => api.delete('/schedules/$id');

  Future<List<RosterEntry>> roster(int scheduleId) =>
      _list('/schedules/$scheduleId/roster', RosterEntry.fromJson);

  // ---- attendance
  Future<List<AttendanceRecord>> myAttendance() =>
      _list('/attendance/me', AttendanceRecord.fromJson);

  Future<List<AttendanceRecord>> attendance() =>
      _list('/attendance', AttendanceRecord.fromJson);

  Future<AttendanceRecord> markAttendance(
          int scheduleId, int memberId, String status) async =>
      AttendanceRecord.fromJson(await api.post('/attendance', body: {
        'schedule_id': scheduleId,
        'member_id': memberId,
        'status': status,
      }) as Map<String, dynamic>);

  Future<AttendanceRecord> updateAttendance(int id, String status) async =>
      AttendanceRecord.fromJson(
          await api.patch('/attendance/$id', body: {'status': status})
              as Map<String, dynamic>);
}