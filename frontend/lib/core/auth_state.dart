import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_client.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Holds the session. The UI switches screens by watching [status].
class AuthState extends ChangeNotifier {
  AuthState(this.api) {
    api.onUnauthorized = _sessionExpired;
  }

  final ApiClient api;
  static const _tokenKey = 'scms_access_token';

  AuthStatus status = AuthStatus.unknown;
  AppUser? user;
  String? notice;

  /// Runs at startup: re-validates a saved token with GET /auth/me.
  /// A minimum splash time lets the kick-off animation actually play.
  Future<void> restore() async {
    final splash =
        Future<void>.delayed(const Duration(milliseconds: 1400));
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);

    var next = AuthStatus.signedOut;
    if (saved != null) {
      api.token = saved;
      try {
        final data = await api.get('/auth/me') as Map<String, dynamic>;
        user = AppUser.fromJson(data);
        next = AuthStatus.signedIn;
      } on ApiException catch (e) {
        api.token = null;
        if (e.status == 401) await prefs.remove(_tokenKey);
      }
    }
    await splash;
    status = next;
    notifyListeners();
  }

  /// Returns null on success, or an error message to show the user.
  Future<String?> login(String email, String password) async {
    try {
      final data = await api.post('/auth/login', body: {
        'email': email.trim(),
        'password': password,
      }) as Map<String, dynamic>;
      final token = data['access_token'] as String;
      api.token = token;
      user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      notice = null;
      status = AuthStatus.signedIn;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _clear();
    notice = null;
    notifyListeners();
  }

  Future<void> _clear() async {
    api.token = null;
    user = null;
    status = AuthStatus.signedOut;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  void _sessionExpired() {
    if (status != AuthStatus.signedIn) return;
    _clear().then((_) {
      notice = 'Your session expired. Please sign in again.';
      notifyListeners();
    });
  }
}