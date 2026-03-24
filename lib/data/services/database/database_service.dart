import 'package:roble_api_database/roble_api_database.dart';
import 'package:uuid/uuid.dart';

import 'package:example/data/services/database/database_service_auth.dart';
import 'package:example/data/services/database/database_service_config.dart';
import 'package:example/data/services/database/database_service_crud.dart';
import 'package:example/data/services/database/database_service_session.dart';

class DatabaseService {
  static const Uuid _uuid = Uuid();
  static const String _defaultDbName = 'example_db_name';
  static const String _studentSessionKey = 'session_student';
  static const String _teacherSessionKey = 'session_teacher';
  static const String _authTokensKey = 'session_auth_tokens';

  final Map<String, String> _tableNameCache = <String, String>{};
  late final DatabaseServiceConfig _config =
      DatabaseServiceConfig(defaultDbName: _defaultDbName);

  late final RobleApiDataBase _roble = RobleApiDataBase(
    config: RobleApiConfig(
      authUrl: _config.buildServiceUrl(_config.authBase, 'auth'),
      dataUrl: _config.buildServiceUrl(_config.dataBase, 'database'),
    ),
  );

  RobleApiDataBase get roble => _roble;

  late final DatabaseServiceAuth _auth = DatabaseServiceAuth(
    roble: _roble,
    authTokensKey: _authTokensKey,
  );

  late final DatabaseServiceCrud _crud = DatabaseServiceCrud(
    roble: _roble,
    tableNameCache: _tableNameCache,
    uuid: _uuid,
  );

  late final DatabaseServiceSession _session = DatabaseServiceSession(
    studentSessionKey: _studentSessionKey,
    teacherSessionKey: _teacherSessionKey,
    saveAuthTokens: saveAuthTokens,
    clearAuthTokens: clearAuthTokens,
  );

  String get studentDefaultPassword => _config.studentDefaultPassword;

  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) {
    return _auth.robleLogin(email: email, password: password);
  }

  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _auth.setSessionTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) {
    return _auth.saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: role,
    );
  }

  Future<Map<String, dynamic>?> readAuthTokens() {
    return _auth.readAuthTokens();
  }

  Future<Map<String, dynamic>> readAuthTokenClaims() {
    return _auth.readAuthTokenClaims();
  }

  Future<void> clearAuthTokens() {
    return _auth.clearAuthTokens();
  }

  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) {
    return _auth.robleSignupDirect(email: email, password: password, name: name);
  }

  Future<void> robleLogout(String accessToken) {
    return _auth.robleLogout(accessToken);
  }

  Future<void> robleCreateTable(
    String tableName,
    List<Map<String, dynamic>> columns,
  ) {
    return _crud.robleCreateTable(tableName, columns);
  }

  Future<dynamic> robleGetTableData(String tableName) {
    return _crud.robleGetTableData(tableName);
  }

  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) {
    return _crud.robleCreate(tableName, data);
  }

  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) {
    return _crud.robleRead(tableName, filters: filters);
  }

  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) {
    return _crud.robleFindUserByEmail(email);
  }

  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) {
    return _crud.robleUpdate(tableName, id, updates);
  }

  Future<Map<String, dynamic>> robleDelete(String tableName, dynamic id) {
    return _crud.robleDelete(tableName, id);
  }

  Map<String, dynamic> decodeJwtClaims(String accessToken) {
    return _auth.decodeJwtClaims(accessToken);
  }

  String? roleFromAccessToken(String accessToken) {
    return _auth.roleFromAccessToken(accessToken);
  }

  static int stableNumericIdFromSeed(String seed) {
    final parsed = int.tryParse(seed);
    if (parsed != null) return parsed;
    return seed.hashCode.abs();
  }

  Future<void> saveStudentSession(Map<String, dynamic> session) {
    return _session.saveStudentSession(session);
  }

  Future<void> saveTeacherSession(Map<String, dynamic> session) {
    return _session.saveTeacherSession(session);
  }

  Future<Map<String, dynamic>?> readStudentSession() {
    return _session.readStudentSession();
  }

  Future<Map<String, dynamic>?> readTeacherSession() {
    return _session.readTeacherSession();
  }

  Future<void> clearStudentSession() {
    return _session.clearStudentSession();
  }

  Future<void> clearTeacherSession() {
    return _session.clearTeacherSession();
  }
}
