import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

typedef SaveAuthTokensFn = Future<void> Function({
  required String accessToken,
  required String refreshToken,
  String? role,
});

typedef ClearAuthTokensFn = Future<void> Function();

class DatabaseServiceSession {
  final String studentSessionKey;
  final String teacherSessionKey;
  final SaveAuthTokensFn saveAuthTokens;
  final ClearAuthTokensFn clearAuthTokens;

  const DatabaseServiceSession({
    required this.studentSessionKey,
    required this.teacherSessionKey,
    required this.saveAuthTokens,
    required this.clearAuthTokens,
  });

  Future<void> saveStudentSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear the opposing role's session to prevent stale role data.
    await prefs.remove(teacherSessionKey);
    await prefs.setString(studentSessionKey, jsonEncode(session));
    final accessToken = session['access_token']?.toString() ?? '';
    final refreshToken = session['refresh_token']?.toString() ?? '';
    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      await saveAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: session['role']?.toString(),
      );
    }
  }

  Future<void> saveTeacherSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    // Clear the opposing role's session to prevent stale role data.
    await prefs.remove(studentSessionKey);
    await prefs.setString(teacherSessionKey, jsonEncode(session));
    final accessToken = session['access_token']?.toString() ?? '';
    final refreshToken = session['refresh_token']?.toString() ?? '';
    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      await saveAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: session['role']?.toString(),
      );
    }
  }

  Future<Map<String, dynamic>?> readStudentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(studentSessionKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  Future<Map<String, dynamic>?> readTeacherSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(teacherSessionKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  Future<void> clearStudentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(studentSessionKey);
    await clearAuthTokens();
  }

  Future<void> clearTeacherSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(teacherSessionKey);
    await clearAuthTokens();
  }
}
