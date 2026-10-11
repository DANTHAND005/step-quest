import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A problem to show the user, like "Wrong username or password".
class ApiError implements Exception {
  ApiError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Every call to the Step Quest server goes through here.
/// New server route? Add one method below that calls [_send].
class Api {
  Api._(this._prefs);

  final SharedPreferences _prefs;

  static Future<Api> load() async => Api._(await SharedPreferences.getInstance());

  /// The Android emulator reaches your PC at 10.0.2.2. Everything else uses localhost.
  static String get defaultServer =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000';

  String get server => _prefs.getString('server') ?? defaultServer;
  String? get token => _prefs.getString('token');
  String? get username => _prefs.getString('username');
  bool get loggedIn => token != null;

  // ---- accounts ----

  Future<void> signup(String server, String username, String password) =>
      _logIn('/auth/signup', server, username, password);

  Future<void> login(String server, String username, String password) =>
      _logIn('/auth/login', server, username, password);

  Future<void> _logIn(String path, String server, String username, String password) async {
    await _prefs.setString('server', server.trim().replaceAll(RegExp(r'/+$'), ''));
    final data = await _send('POST', path, {'username': username.trim(), 'password': password});
    await _prefs.setString('token', data['token'] as String);
    await _prefs.setString('username', username.trim());
  }

  Future<void> logout() async {
    await _prefs.remove('token');
    await _prefs.remove('username');
  }

  // ---- data ----

  /// {username, today, week, total, coins}
  Future<Map<String, dynamic>> me() async => await _send('GET', '/me') as Map<String, dynamic>;

  /// {friends: [{id, username}], requests: [{id, username}]}
  Future<Map<String, dynamic>> friends() async =>
      await _send('GET', '/friends') as Map<String, dynamic>;

  Future<void> requestFriend(String username) =>
      _send('POST', '/friends/request', {'username': username.trim()});

  Future<void> acceptFriend(int fromId) => _send('POST', '/friends/$fromId/accept');

  /// [{username, steps}], most steps first. [range] is 'today' or 'week'.
  Future<List<dynamic>> leaderboard(String range) async =>
      await _send('GET', '/leaderboard?range=$range') as List<dynamic>;

  // ---- the one place that talks HTTP ----

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$server$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final http.Response res;
    try {
      final request = method == 'GET'
          ? http.get(uri, headers: headers)
          : http.post(uri, headers: headers, body: jsonEncode(body ?? {}));
      res = await request.timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiError("Can't reach the server at $server. Is it running?");
    }

    final data = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode == 401 && !path.startsWith('/auth')) {
      throw ApiError('Your login expired. Log out from Profile and log in again.');
    }
    if (res.statusCode >= 400) throw ApiError(_errorMessage(data));
    return data;
  }

  /// The server sends {"detail": "message"} or, for invalid fields, {"detail": [{"msg": ...}]}.
  static String _errorMessage(dynamic data) {
    final detail = data is Map ? data['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      return '${detail.first['msg']}';
    }
    return 'Something went wrong. Try again.';
  }
}
