import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:roble_api_database/roble_api_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:example/data/services/roble_schema.dart';

class DatabaseService {
  static const Uuid _uuid = Uuid();
  static const String _defaultDbName = 'evalun_5268a77998';
  static const String _studentSessionKey = 'session_student';
  static const String _teacherSessionKey = 'session_teacher';
  static const String _authTokensKey = 'session_auth_tokens';

  final Map<String, String> _tableNameCache = <String, String>{};

  late final RobleApiDataBase roble = RobleApiDataBase(
    config: RobleApiConfig(
      authUrl: _buildServiceUrl(_authBase, 'auth'),
      dataUrl: _buildServiceUrl(_dataBase, 'database'),
    ),
  );

  String get _dbName {
    final envDb = dotenv.isInitialized ? dotenv.env['ROBLE_DB_NAME'] : null;
    if (envDb != null && envDb.isNotEmpty) return envDb;
    final fromDefine = const String.fromEnvironment(
      'ROBLE_DB_NAME',
      defaultValue: _defaultDbName,
    );
    if (fromDefine.isNotEmpty) return fromDefine;
    return _defaultDbName;
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

  String get studentDefaultPassword {
    final envPwd = dotenv.isInitialized
        ? dotenv.env['ROBLE_STUDENT_DEFAULT_PASSWORD']
        : null;
    if (envPwd != null && envPwd.isNotEmpty) return envPwd;
    return const String.fromEnvironment(
      'ROBLE_STUDENT_DEFAULT_PASSWORD',
      defaultValue: 'Password123!',
    );
  }

  String _trimSlashes(String value) => value.trim().replaceAll(RegExp(r'/+$'), '');

  String _buildServiceUrl(String rawBase, String segment) {
    final base = _trimSlashes(rawBase);
    final db = _dbName.trim();
    final lower = base.toLowerCase();
    final segmentLower = segment.toLowerCase();
    final dbLower = db.toLowerCase();

    final effectiveDb = db.isEmpty ? _defaultDbName : db;

    // Already in canonical form: .../auth/:dbName or .../database/:dbName
    if (lower.endsWith('/$segmentLower/$dbLower') ||
        lower.endsWith('/$segmentLower/${_defaultDbName.toLowerCase()}')) {
      return base;
    }

    // Base points to service root: .../auth or .../database
    if (lower.endsWith('/$segmentLower')) {
      return '$base/$effectiveDb';
    }

    // Base is full host root: ...
    return '$base/$segment/$effectiveDb';
  }

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
      _authTokensKey,
      jsonEncode({
        'access_token': accessToken,
        'refresh_token': refreshToken,
        if (role != null && role.isNotEmpty) 'role': role,
      }),
    );
  }

  Future<Map<String, dynamic>?> readAuthTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authTokensKey);
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
    await prefs.remove(_authTokensKey);
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
    final resolved = await _resolveTableName(tableName);
    await roble.createTable(resolved, columns);
  }

  Future<dynamic> robleGetTableData(String tableName) async {
    final resolved = await _resolveTableName(tableName);
    return roble.getTableData(resolved);
  }

  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final resolvedTableName = await _resolveTableName(tableName);
    final payload = _normalizeFieldsForTable(resolvedTableName, data);
    final primaryField = _primaryKeyFieldForTable(resolvedTableName);

    if (primaryField != RobleFields.rowId) {
      if (!payload.containsKey(primaryField) || payload[primaryField] == null) {
        payload[primaryField] = _uuid.v4();
      } else {
        payload[primaryField] = payload[primaryField].toString();
      }
    }

    final row = await roble.create(resolvedTableName, payload);

    final hasPrimaryKey = _rowHasPrimaryKey(row, resolvedTableName);
    if (hasPrimaryKey) return row;

    final skipped = row['skipped'];
    if (skipped is List && skipped.isNotEmpty) {
      final reason = (skipped.first is Map)
          ? (skipped.first['reason']?.toString() ?? skipped.first.toString())
          : skipped.first.toString();
      throw Exception('Insert rechazado en $resolvedTableName: $reason');
    }

    throw Exception(
      'Insert sin fila valida en $resolvedTableName. Respuesta: ${jsonEncode(row)}',
    );
  }

  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final resolved = await _resolveTableName(tableName);
    final resolvedFilters =
        filters == null ? null : _normalizeFieldsForTable(resolved, filters);
    return roble.read(resolved, filters: resolvedFilters);
  }

  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();

    final direct = await robleRead(RobleTables.users, filters: {'email': normalized});
    if (direct.isNotEmpty) return direct.first;

    // Fallback for projects where stored email casing does not match exactly.
    final allUsers = await robleRead(RobleTables.users);
    for (final user in allUsers) {
      final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      if (userEmail == normalized) return user;
    }
    return null;
  }

  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final resolved = await _resolveTableName(tableName);
    final normalizedUpdates = _normalizeFieldsForTable(resolved, updates);
    return roble.update(resolved, id, normalizedUpdates);
  }

  Future<Map<String, dynamic>> robleDelete(String tableName, dynamic id) async {
    final resolved = await _resolveTableName(tableName);
    return roble.delete(resolved, id);
  }

  Future<String> _resolveTableName(String requestedName) async {
    final requested = requestedName.trim();
    if (requested.isEmpty) return requestedName;

    final cached = _tableNameCache[requested];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final aliases = RobleSchema.tableAliases[requested] ?? <String>[requested];
    final seen = <String>{};
    final candidates = <String>[];
    for (final name in aliases) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      candidates.add(trimmed);
    }

    for (final candidate in candidates) {
      try {
        await roble.read(candidate);
        _tableNameCache[requested] = candidate;
        return candidate;
      } catch (_) {
        // Try next alias.
      }
    }

    _tableNameCache[requested] = requested;
    return requested;
  }

  String _logicalTableKey(String tableName) {
    final requested = tableName.trim();
    if (requested.isEmpty) return tableName;

    for (final entry in RobleSchema.tableAliases.entries) {
      if (entry.key == requested || entry.value.contains(requested)) {
        return entry.key;
      }
    }
    return requested;
  }

  String _primaryKeyFieldForTable(String tableName) {
    final logical = _logicalTableKey(tableName);
    return RobleSchema.tablePrimaryKeys[logical] ?? '${logical}_id';
  }

  List<String> _primaryKeyAliasesForTable(String tableName) {
    final logical = _logicalTableKey(tableName);
    final primary = _primaryKeyFieldForTable(tableName);
    final aliases =
        RobleSchema.fieldAliasesByTable[logical]?[primary] ?? const <String>[];
    final seen = <String>{};
    final keys = <String>[];

    for (final key in <String>[primary, ...aliases, RobleFields.rowId, RobleFields.id]) {
      final trimmed = key.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      keys.add(trimmed);
    }
    return keys;
  }

  bool _rowHasPrimaryKey(Map<String, dynamic> row, String tableName) {
    final candidates = _primaryKeyAliasesForTable(tableName);
    for (final key in candidates) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _normalizeFieldsForTable(
    String tableName,
    Map<String, dynamic> source,
  ) {
    final logical = _logicalTableKey(tableName);
    final aliasesByCanonical = RobleSchema.fieldAliasesByTable[logical];
    if (aliasesByCanonical == null || aliasesByCanonical.isEmpty) {
      return Map<String, dynamic>.from(source);
    }

    final aliasToCanonical = <String, String>{};
    for (final entry in aliasesByCanonical.entries) {
      for (final alias in entry.value) {
        aliasToCanonical[alias] = entry.key;
      }
    }

    final canonicalPresent = <String>{};
    for (final key in source.keys) {
      if (aliasesByCanonical.containsKey(key)) {
        canonicalPresent.add(key);
      }
    }

    final normalized = <String, dynamic>{};
    for (final entry in source.entries) {
      final fromAlias = aliasToCanonical[entry.key];
      if (fromAlias != null && canonicalPresent.contains(fromAlias)) {
        continue;
      }
      final targetKey = fromAlias ?? entry.key;
      normalized.putIfAbsent(targetKey, () => entry.value);
    }

    return normalized;
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
    await prefs.setString(_teacherSessionKey, jsonEncode(session));
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
    await clearAuthTokens();
  }

  Future<void> clearTeacherSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_teacherSessionKey);
    await clearAuthTokens();
  }
}
