import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Backend address. Override per target without editing code:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.5:8000
const String kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000');

class ApiException implements Exception {
  ApiException(this.message, {this.status});
  final String message;
  final int? status;

  @override
  String toString() => message;
}

/// Thin wrapper around http: adds the token, parses FastAPI errors into
/// readable messages and reports expired sessions.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? token;
  void Function()? onUnauthorized;

  Uri _uri(String path, Map<String, String>? query) =>
      Uri.parse('$kApiBaseUrl$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<dynamic> _send(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final request = http.Request(method, _uri(path, query));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    } on http.ClientException {
      throw ApiException("Can't reach the server. Is the backend running?");
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    if (response.statusCode == 401 && token != null) onUnauthorized?.call();
    throw ApiException(_errorMessage(response), status: response.statusCode);
  }

  String _errorMessage(http.Response r) {
    try {
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final detail = data is Map ? data['detail'] : null;
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          final loc = first['loc'] is List
              ? (first['loc'] as List).where((e) => e != 'body').join(' > ')
              : '';
          final msg = first['msg'] as String;
          return loc.isEmpty ? msg : '$loc: $msg';
        }
      }
    } catch (_) {
      // fall through to the generic message
    }
    return 'Something went wrong (HTTP ${r.statusCode}).';
  }
}