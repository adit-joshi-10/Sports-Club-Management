import '../models/club_models.dart';
import 'api_client.dart';

/// All club data calls live here, so screens never build URLs themselves.
class ClubRepository {
  ClubRepository(this.api);

  final ApiClient api;

  // ---- sports ----
  Future<List<Sport>> sports() async {
    final data = await api.get('/sports') as List<dynamic>;
    return data
        .map((e) => Sport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Sport> createSport(Map<String, dynamic> body) async {
    final data = await api.post('/sports', body: body);
    return Sport.fromJson(data as Map<String, dynamic>);
  }

  Future<Sport> updateSport(int id, Map<String, dynamic> body) async {
    final data = await api.patch('/sports/$id', body: body);
    return Sport.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSport(int id) => api.delete('/sports/$id');

  // ---- members ----
  Future<Member> myProfile() async {
    final data = await api.get('/members/me');
    return Member.fromJson(data as Map<String, dynamic>);
  }

  /// Admin only (the server enforces it). [search] is matched on the server.
  Future<List<Member>> members({String? search}) async {
    final q = search?.trim() ?? '';
    final data = await api.get('/members',
        query: q.isEmpty ? null : {'search': q}) as List<dynamic>;
    return data
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> memberCount() async => (await members()).length;

  Future<Member> createMember(Map<String, dynamic> body) async {
    final data = await api.post('/members', body: body);
    return Member.fromJson(data as Map<String, dynamic>);
  }

  Future<Member> updateMember(int id, Map<String, dynamic> body) async {
    final data = await api.patch('/members/$id', body: body);
    return Member.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteMember(int id) => api.delete('/members/$id');
}