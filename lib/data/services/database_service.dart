import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:roble_api_database/roble_api_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static const String _studentSessionKey = 'session_student';
  static const String _teacherSessionKey = 'session_teacher';

  late final RobleApiDataBase roble = RobleApiDataBase(
    config: RobleApiConfig(
      authUrl: '$_authBase/$_dbName',
      dataUrl: '$_dataBase/$_dbName',
    ),
  );

  String get _dbName {
    final envDb = dotenv.isInitialized ? dotenv.env['ROBLE_DB_NAME'] : null;
    if (envDb != null && envDb.isNotEmpty) return envDb;
    return const String.fromEnvironment(
      'ROBLE_DB_NAME',
    );
  }

  String get _authBase {
    final envUrl =
        dotenv.isInitialized ? dotenv.env['ROBLE_AUTH_BASE_URL'] : null;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'https://roble-api.openlab.uninorte.edu.co/auth';
  }

  String get _dataBase {
    final envUrl =
        dotenv.isInitialized ? dotenv.env['ROBLE_DATA_BASE_URL'] : null;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return 'https://roble-api.openlab.uninorte.edu.co/database';
  }

  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    return roble.login(email: email, password: password);
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

  Future<void> robleCreateTable(
    String tableName,
    List<Map<String, dynamic>> columns,
  ) async {
    await roble.createTable(tableName, columns);
  }

  Future<dynamic> robleGetTableData(String tableName) async {
    return roble.getTableData(tableName);
  }

  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    return roble.create(tableName, data);
  }

  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    return roble.read(tableName, filters: filters);
  }

  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    return roble.update(tableName, id, updates);
  }

  Future<Map<String, dynamic>> robleDelete(String tableName, dynamic id) async {
    return roble.delete(tableName, id);
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

  static int stableNumericIdFromSeed(String seed) {
    final parsed = int.tryParse(seed);
    if (parsed != null) return parsed;
    return seed.hashCode.abs();
  }

  Future<void> saveStudentSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_studentSessionKey, jsonEncode(session));
  }

  Future<void> saveTeacherSession(Map<String, dynamic> session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_teacherSessionKey, jsonEncode(session));
  }

  Future<Map<String, dynamic>?> readStudentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studentSessionKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  Future<Map<String, dynamic>?> readTeacherSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_teacherSessionKey);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw);
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return null;
  }

  Future<void> clearStudentSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_studentSessionKey);
  }

  Future<void> clearTeacherSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teacherSessionKey);
  }
}
