import 'dart:convert';

import 'package:roble_api_database/roble_api_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseServiceAuth {
  final RobleApiDataBase roble;
  final String authTokensKey;

  const DatabaseServiceAuth({
    required this.roble,
    required this.authTokensKey,
  });

  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    return roble.login(email: email, password: password);
  }

  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    roble.setTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      authTokensKey,
      jsonEncode({
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (role != null && role.isNotEmpty) 'role': role,
      }),
    );
  }

  Future<Map<String, dynamic>?> readAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(authTokensKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  Future<Map<String, dynamic>> readAuthTokenClaims() async {
    final tokens = await readAuthTokens();
    if (tokens == null) return const {};
    final accessToken = tokens['access_token']?.toString() ?? '';
    if (accessToken.isEmpty) return const {};
    return decodeJwtClaims(accessToken);
  }

  Future<void> clearAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authTokensKey);
  }

  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) async {
    return roble.register(email: email, password: password, name: name);
  }

  Future<void> robleLogout(String accessToken) async {
    await roble.logout(accessToken: accessToken);
  }

  Map<String, dynamic> decodeJwtClaims(String accessToken) {
    final parts = accessToken.split('.');
    if (parts.length < 2) return const {};
    final payload = base64Url.normalize(parts[1]);
    final jsonMap = jsonDecode(utf8.decode(base64Url.decode(payload)));
    if (jsonMap is Map<String, dynamic>) return jsonMap;
    if (jsonMap is Map) return Map<String, dynamic>.from(jsonMap);
    return const {};
  }

  String? roleFromAccessToken(String accessToken) {
    final claims = decodeJwtClaims(accessToken);
    final role = claims['role'];
    return role?.toString();
  }
}
