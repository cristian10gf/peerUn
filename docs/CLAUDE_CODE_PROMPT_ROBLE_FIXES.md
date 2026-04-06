# Contexto
Estás trabajando en un proyecto Flutter llamado EvalUn/Evalia. Es una app de peer assessment universitaria que se integra con la plataforma Roble (BaaS de OpenLab, Uninorte). El proyecto usa Clean Architecture + GetX.

Se han identificado **10 bugs críticos** en la integración con Roble, incluyendo problemas de rendimiento severos (el import de CSV de 33 estudiantes hace ~165 llamadas API secuenciales cuando debería hacer ~15-20). Esta tarea es SOLO aplicar los fixes ya diseñados — no cambiar nada más del proyecto.

---

# INSTRUCCIONES GENERALES

- Lee cada archivo actual ANTES de sobreescribirlo para confirmar que entiendes la estructura
- Preserva EXACTAMENTE los estilos de código, imports y comentarios existentes donde no haya cambios indicados
- NO modifiques ningún archivo de UI, tests, ni archivos no listados aquí
- Después de aplicar todos los cambios, ejecuta `flutter analyze` y corrige cualquier error de compilación
- NO ejecutes `flutter test` — solo `flutter analyze`

---

# CAMBIO 1 — pubspec.yaml

Lee `pubspec.yaml`. Agrega `http: ^1.6.0` como dependencia directa en la sección `dependencies:`, debajo de `uuid`. El paquete `http` ya es una dependencia transitiva de `roble_api_database` pero debe declararse explícitamente.

```yaml
# Agregar esta línea bajo dependencies:
  http: ^1.6.0
```

Después ejecuta `flutter pub get`.

---

# CAMBIO 2 — lib/data/services/database/database_service_crud.dart

**REEMPLAZA el archivo completo** con el siguiente contenido:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:roble_api_database/roble_api_database.dart';
import 'package:uuid/uuid.dart';

import 'package:example/data/services/roble_schema.dart';

/// CRUD operations adapter for the Roble API.
///
/// Key facts from official Roble docs (2026):
///  • POST /:dbName/insert  → body: { tableName, records: [...] }
///                           → response: { inserted: [...], skipped: [...] }
///  • GET  /:dbName/read    → query: tableName + equality filters
///                           → response: Array of matching rows
///  • PUT  /:dbName/update  → body: { tableName, idColumn, idValue, updates }
///  • DELETE/:dbName/delete → body: { tableName, idColumn, idValue }
///
/// The [roble_api_database] package wraps single-record CRUD correctly.
/// Bulk insert is called directly via [http] because the package only exposes
/// single-record creation.
class DatabaseServiceCrud {
  final RobleApiDataBase roble;
  final Map<String, String> tableNameCache;
  final Uuid uuid;

  // These are set externally when the teacher session is active so that
  // robleBulkInsert can attach the Authorization header.
  String _currentAccessToken = '';
  String _dataBaseUrl = '';

  DatabaseServiceCrud({
    required this.roble,
    required this.tableNameCache,
    required this.uuid,
  });

  /// Called by [DatabaseService] to keep the active token in sync.
  void setCurrentToken(String accessToken, String dataBaseUrl) {
    _currentAccessToken = accessToken;
    _dataBaseUrl = dataBaseUrl;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Table management
  // ─────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // Single-record CRUD (delegates to the package)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final resolvedTableName = await _resolveTableName(tableName);
    final payload = _normalizeFieldsForTable(resolvedTableName, data);

    // The package's create() wraps POST /insert with records:[payload].
    // We do NOT pre-generate _id here — Roble auto-generates a 12-char _id
    // when not provided. If the canonical PK field (user_id, category_id, …)
    // is missing, generate a UUID for it so joins work predictably.
    final primaryField = _primaryKeyFieldForTable(resolvedTableName);
    if (primaryField != RobleFields.rowId) {
      if (!payload.containsKey(primaryField) || payload[primaryField] == null) {
        payload[primaryField] = uuid.v4();
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
      'Insert sin fila válida en $resolvedTableName. Respuesta: ${jsonEncode(row)}',
    );
  }

  /// Inserts multiple records in a single Roble API call.
  ///
  /// Roble endpoint: POST /:dbName/insert
  /// Body: { tableName, records: [...] }
  /// Response: { inserted: [...], skipped: [...] }
  ///
  /// Returns the list of successfully inserted rows.
  /// Throws if the network call fails or ALL records are skipped.
  Future<List<Map<String, dynamic>>> robleBulkInsert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    if (records.isEmpty) return const [];

    final resolvedTableName = await _resolveTableName(tableName);
    final primaryField = _primaryKeyFieldForTable(resolvedTableName);

    // Normalise each record the same way single inserts are normalised.
    final normalised = records.map((record) {
      final payload = _normalizeFieldsForTable(resolvedTableName, record);
      if (primaryField != RobleFields.rowId) {
        if (!payload.containsKey(primaryField) || payload[primaryField] == null) {
          payload[primaryField] = uuid.v4();
        } else {
          payload[primaryField] = payload[primaryField].toString();
        }
      }
      return payload;
    }).toList(growable: false);

    // Call the Roble bulk insert endpoint directly.
    final url = '$_dataBaseUrl/insert';
    final headers = {
      'Content-Type': 'application/json',
      if (_currentAccessToken.isNotEmpty)
        'Authorization': 'Bearer $_currentAccessToken',
    };
    final body = jsonEncode({
      'tableName': resolvedTableName,
      'records': normalised,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Bulk insert falló en $resolvedTableName '
        '[${response.statusCode}]: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw Exception(
        'Respuesta inesperada de bulk insert: ${response.body}',
      );
    }

    final inserted = decoded['inserted'];
    if (inserted is List) {
      return inserted
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }

    // Some Roble versions return the array directly.
    if (decoded is List) {
      return (decoded as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }

    // If nothing was inserted but the request succeeded, return empty.
    return const [];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────────────────

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

    // Try direct filter first (fast path).
    final direct =
        await robleRead(RobleTables.users, filters: {'email': normalized});
    if (direct.isNotEmpty) return direct.first;

    // Fall back to full-scan (slow path — only when direct filter returns nothing).
    final allUsers = await robleRead(RobleTables.users);
    for (final user in allUsers) {
      final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      if (userEmail == normalized) return user;
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Update / Delete
  // ─────────────────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _resolveTableName(String requestedName) async {
    final requested = requestedName.trim();
    if (requested.isEmpty) return requestedName;

    final cached = tableNameCache[requested];
    if (cached != null && cached.isNotEmpty) return cached;

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
        tableNameCache[requested] = candidate;
        return candidate;
      } catch (_) {
        // Try next alias.
      }
    }

    tableNameCache[requested] = requested;
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
    for (final key in <String>[
      primary,
      ...aliases,
      RobleFields.rowId,
      RobleFields.id,
    ]) {
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
      if (value != null && value.toString().isNotEmpty) return true;
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
      if (aliasesByCanonical.containsKey(key)) canonicalPresent.add(key);
    }

    final normalized = <String, dynamic>{};
    for (final entry in source.entries) {
      final fromAlias = aliasToCanonical[entry.key];
      if (fromAlias != null && canonicalPresent.contains(fromAlias)) continue;
      final targetKey = fromAlias ?? entry.key;
      normalized.putIfAbsent(targetKey, () => entry.value);
    }
    return normalized;
  }
}
```

---

# CAMBIO 3 — lib/data/services/database/database_service.dart

**REEMPLAZA el archivo completo** con el siguiente contenido. La diferencia clave respecto al original es que `setSessionTokens` ahora sincroniza el CRUD layer, y se expone el nuevo método `robleBulkInsert`:

```dart
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

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) {
    return _auth.robleLogin(email: email, password: password);
  }

  /// Sets the active session tokens on both the auth layer AND the CRUD layer
  /// so that robleBulkInsert can attach the Authorization header.
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    _auth.setSessionTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    // Keep CRUD in sync so bulk HTTP calls use the current token.
    _crud.setCurrentToken(
      accessToken,
      _config.buildServiceUrl(_config.dataBase, 'database'),
    );
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

  Map<String, dynamic> decodeJwtClaims(String accessToken) {
    return _auth.decodeJwtClaims(accessToken);
  }

  String? roleFromAccessToken(String accessToken) {
    return _auth.roleFromAccessToken(accessToken);
  }

  // ─── Table management ────────────────────────────────────────────────────

  Future<void> robleCreateTable(
    String tableName,
    List<Map<String, dynamic>> columns,
  ) {
    return _crud.robleCreateTable(tableName, columns);
  }

  Future<dynamic> robleGetTableData(String tableName) {
    return _crud.robleGetTableData(tableName);
  }

  // ─── Single-record CRUD ──────────────────────────────────────────────────

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

  /// Inserts multiple records in a SINGLE Roble API call.
  ///
  /// Uses POST /:dbName/insert with body { tableName, records: [...] }.
  /// Dramatically faster than N individual [robleCreate] calls when importing
  /// CSVs or batch-creating relations.
  ///
  /// Returns the list of successfully inserted rows.
  Future<List<Map<String, dynamic>>> robleBulkInsert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) {
    return _crud.robleBulkInsert(tableName, records);
  }

  // ─── ID helpers ─────────────────────────────────────────────────────────

  static int stableNumericIdFromSeed(String seed) {
    final parsed = int.tryParse(seed);
    if (parsed != null) return parsed;
    return seed.hashCode.abs();
  }

  // ─── Session ─────────────────────────────────────────────────────────────

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
```

---

# CAMBIO 4 — lib/data/repositories/group_repository_impl.dart

**REEMPLAZA el archivo completo** con el siguiente contenido. Este es el cambio más importante: el método `importCsv` pasa de ~165 llamadas secuenciales a ~15-20 usando bulk inserts y signup paralelo:

```dart
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/email_utils.dart';
import 'package:example/data/utils/repository_db_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/services/csv_import_domain_service.dart';

/// Maximum number of concurrent signup-direct calls during CSV import.
const _kSignupConcurrency = 5;

class GroupRepositoryImpl implements IGroupRepository {
  final DatabaseService _db;
  final CsvImportDomainService _csvImportDomainService;

  GroupRepositoryImpl(
    this._db, {
    CsvImportDomainService? csvImportDomainService,
  }) : _csvImportDomainService =
           csvImportDomainService ?? const CsvImportDomainService();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool _looksLikeAlreadyRegistered(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('409') ||
        msg.contains('registrado') ||
        msg.contains('already') ||
        msg.contains('duplicate');
  }

  String _asString(dynamic value) => value?.toString().trim() ?? '';

  String _firstNonEmpty(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final v = _asString(row[key]);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _userRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['user_id', 'id', '_id']);

  String _courseRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['course_id', 'id', '_id']);

  String _categoryRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['category_id', 'id', '_id']);

  String _groupRef(Map<String, dynamic> row) =>
      _firstNonEmpty(row, const ['group_id', 'id', '_id']);

  int _domainId(String reference, {required int fallback}) {
    if (reference.isEmpty) return fallback;
    return DatabaseService.stableNumericIdFromSeed(reference);
  }

  /// Extracts the auth user-id (sub) from a [signupResponse].
  ///
  /// Roble's signup-direct does not always return the UID in the body, but it
  /// always issues a JWT whose `sub` claim IS the UID. We try three sources
  /// in order of reliability:
  ///   1. `accessToken` JWT `sub` claim
  ///   2. Top-level `user_id` / `uid` / `sub` fields
  ///   3. Nested `user.id` object
  String _extractAuthUserId(Map<String, dynamic> payload) {
    // 1. Decode JWT sub if accessToken is present (most reliable).
    final accessToken = _asString(
      payload['accessToken'] ?? payload['access_token'],
    );
    if (accessToken.isNotEmpty) {
      final claims = _db.decodeJwtClaims(accessToken);
      final sub = _asString(claims['sub']);
      if (sub.isNotEmpty) return sub;
    }

    // 2. Top-level fields.
    for (final key in const [
      'user_id',
      'userId',
      'uid',
      'sub',
      '_id',
      'id',
    ]) {
      final v = _asString(payload[key]);
      if (v.isNotEmpty) return v;
    }

    // 3. Nested user object.
    final user = payload['user'];
    if (user is Map) {
      for (final key in const ['user_id', 'userId', 'uid', 'sub', '_id', 'id']) {
        final v = _asString(user[key]);
        if (v.isNotEmpty) return v;
      }
    }

    return '';
  }

  /// Runs [tasks] with at most [maxConcurrent] running simultaneously.
  Future<List<T>> _runConcurrent<T>(
    List<Future<T> Function()> tasks, {
    int maxConcurrent = _kSignupConcurrency,
  }) async {
    final results = <T>[];
    for (var i = 0; i < tasks.length; i += maxConcurrent) {
      final chunk = tasks.skip(i).take(maxConcurrent).toList();
      final chunkResults = await Future.wait(chunk.map((t) => t()));
      results.addAll(chunkResults);
    }
    return results;
  }

  // ─── Public interface ────────────────────────────────────────────────────

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async {
    final catRows = await _db.robleRead(RobleTables.category);
    final courseRows = await _db.robleRead(RobleTables.course);
    final usersRows = await _db.robleRead(RobleTables.users);

    final usersByRef = <String, Map<String, dynamic>>{};
    for (final u in usersRows) {
      for (final key in const ['user_id', 'id', '_id']) {
        final v = _asString(u[key]);
        if (v.isNotEmpty) usersByRef.putIfAbsent(v, () => u);
      }
    }

    final teacherCourseIds = <int>{};
    if (await tableExists(_db, RobleTables.userCourse)) {
      final claims = await _db.readAuthTokenClaims();
      final email = (claims['email'] ?? '').toString().trim().toLowerCase();
      if (email.isNotEmpty) {
        final teacherUser = await _db.robleFindUserByEmail(email);
        final candidates = <String>{
          _asString(teacherUser?['user_id']),
          _asString(teacherUser?['id']),
          _asString(teacherUser?['_id']),
        }..removeWhere((v) => v.isEmpty);

        for (final candidate in candidates) {
          final relations = await _db.robleRead(
            RobleTables.userCourse,
            filters: {'user_id': candidate, 'role': 'teacher'},
          );
          for (final rel in relations) {
            teacherCourseIds.add(asInt(rel['course_id']));
          }
        }
      }
    }

    if (teacherCourseIds.isEmpty) {
      for (final c in courseRows) {
        final createdBy = asInt(c['created_by'] ?? c['teacher_id']);
        if (createdBy != teacherId) continue;
        final ref = _courseRef(c);
        teacherCourseIds.add(
          _domainId(ref, fallback: rowIdFromMap(c)),
        );
      }
    }

    if (teacherCourseIds.isEmpty) return const <GroupCategory>[];

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final courseId = asInt(cat['course_id']);
      if (!teacherCourseIds.contains(courseId)) continue;

      final catReference = _categoryRef(cat);
      final catId = _domainId(catReference, fallback: rowIdFromMap(cat));

      var grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': catReference},
      );
      if (grpRows.isEmpty) {
        grpRows = await _db.robleRead(
          RobleTables.groups,
          filters: {'category_id': catId.toString()},
        );
      }

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final groupReference = _groupRef(grp);
        final grpId = _domainId(groupReference, fallback: rowIdFromMap(grp));

        var memberRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': groupReference},
        );
        if (memberRows.isEmpty) {
          memberRows = await _db.robleRead(
            RobleTables.userGroup,
            filters: {'group_id': grpId.toString()},
          );
        }

        final members = <GroupMember>[];
        for (final membership in memberRows) {
          final userReference = _asString(membership['user_id']);
          if (userReference.isEmpty) continue;
          final user = usersByRef[userReference];
          if (user == null) continue;
          final userId = _domainId(
            userReference,
            fallback: asInt(user['id'] ?? user['_id']),
          );
          members.add(
            GroupMember(
              id: userId,
              name: (user['name'] ?? '').toString(),
              username: (user['email'] ?? '').toString(),
            ),
          );
        }

        groups.add(
          CourseGroup(
            id: grpId,
            name: (grp['name'] ?? '').toString(),
            members: members,
          ),
        );
      }

      result.add(
        GroupCategory(
          id: catId,
          name: (cat['name'] ?? '').toString(),
          importedAt: asDate(cat['created_at'] ?? cat['imported_at']),
          groups: groups,
          courseId: courseId,
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }

  // ─── importCsv ────────────────────────────────────────────────────────────
  //
  // OPTIMISED STRATEGY (from ~165 sequential calls → ~15-20 total):
  //
  //  Pre-load  : 1 read(users) + 1 read(user_group) + 1 read(user_course)
  //              + 1 read(course) = 4 reads
  //  Phase 1   : N parallel signup-direct (only NEW students, concurrency 5)
  //  Phase 2   : 1 bulk insert → user table
  //  Phase 3   : 1 create → category
  //  Phase 4   : G creates → groups (G = number of groups, typically ≤15)
  //  Phase 5   : 1 bulk insert → user_group relations
  //  Phase 6   : 1 bulk insert → user_course relations
  //
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  ) async {
    // ── Guard: need a valid teacher token to make auth calls ────────────────
    final teacherTokens = await _db.readAuthTokens();
    final teacherAccessToken = teacherTokens?['access_token']?.toString() ?? '';
    final teacherRefreshToken =
        teacherTokens?['refresh_token']?.toString() ?? '';
    if (teacherAccessToken.isEmpty || teacherRefreshToken.isEmpty) {
      throw Exception('Sesión de profesor no válida para aprovisionar datos');
    }

    // ── Parse CSV ────────────────────────────────────────────────────────────
    final parsed = _csvImportDomainService.parse(csvContent);

    // ── PRE-LOAD: fetch tables we need in one pass ───────────────────────────
    final allUsers = await _db.robleRead(RobleTables.users);
    final allCourses = await _db.robleRead(RobleTables.course);

    final hasUserCourseTable = await tableExists(_db, RobleTables.userCourse);
    final hasUserGroupTable = await tableExists(_db, RobleTables.userGroup);

    // Read existing relations once (warm-up cache).
    final existingUserCourseKeys = <String>{};
    final existingUserGroupKeys = <String>{};
    if (hasUserCourseTable) {
      final rows = await _db.robleRead(RobleTables.userCourse);
      for (final r in rows) {
        final cid = _asString(r['course_id']);
        final uid = _asString(r['user_id']);
        if (cid.isNotEmpty && uid.isNotEmpty) {
          existingUserCourseKeys.add('$cid::$uid');
        }
      }
    }
    if (hasUserGroupTable) {
      final rows = await _db.robleRead(RobleTables.userGroup);
      for (final r in rows) {
        final gid = _asString(r['group_id']);
        final uid = _asString(r['user_id']);
        if (gid.isNotEmpty && uid.isNotEmpty) {
          existingUserGroupKeys.add('$gid::$uid');
        }
      }
    }

    // Build per-email lookups from the pre-loaded users.
    final usersByEmail = <String, Map<String, dynamic>>{};
    final authIdByEmail = <String, String>{};
    for (final row in allUsers) {
      final email = normalizeEmail((row['email'] ?? '').toString());
      if (email.isEmpty) continue;
      usersByEmail[email] = row;
      final authId = _asString(row['user_id']);
      if (authId.isNotEmpty) authIdByEmail[email] = authId;
    }

    // Resolve the course's canonical reference (used for user_course FK).
    final courseReference = _resolveCourseRef(allCourses, courseId);

    // ── Collect unique emails from CSV ───────────────────────────────────────
    final uniqueEmails = <String>{};
    for (final group in parsed.groups) {
      for (final member in group.members) {
        uniqueEmails.add(normalizeEmail(member.username));
      }
    }
    final newEmails =
        uniqueEmails.where((e) => !authIdByEmail.containsKey(e)).toList();

    // ── PHASE 1: Parallel signup-direct for new students ─────────────────────
    if (newEmails.isNotEmpty) {
      final signupTasks = newEmails.map((email) => () async {
        // Find name from CSV (use first occurrence).
        String name = email.split('@').first;
        outer:
        for (final group in parsed.groups) {
          for (final member in group.members) {
            if (normalizeEmail(member.username) == email) {
              name = member.name;
              break outer;
            }
          }
        }

        try {
          final signupResponse = await _db.robleSignupDirect(
            email: email,
            password: _db.studentDefaultPassword,
            name: name,
          );
          final authId = _extractAuthUserId(signupResponse);
          if (authId.isNotEmpty) authIdByEmail[email] = authId;
        } catch (e) {
          if (!_looksLikeAlreadyRegistered(e)) rethrow;
          // Already registered — authId may already be in the map or will be
          // resolved from the users table pre-load above.
        }

        // Restore teacher token context after each signup attempt.
        _db.setSessionTokens(
          accessToken: teacherAccessToken,
          refreshToken: teacherRefreshToken,
        );
      }).toList();

      await _runConcurrent(signupTasks);

      // Ensure teacher token is active for subsequent DB writes.
      _db.setSessionTokens(
        accessToken: teacherAccessToken,
        refreshToken: teacherRefreshToken,
      );
    }

    // ── PHASE 2: Bulk upsert users table ─────────────────────────────────────
    final userRecordsToInsert = <Map<String, dynamic>>[];
    for (final email in uniqueEmails) {
      if (usersByEmail.containsKey(email)) continue; // Already in DB.

      String name = email.split('@').first;
      outer:
      for (final group in parsed.groups) {
        for (final member in group.members) {
          if (normalizeEmail(member.username) == email) {
            name = member.name;
            break outer;
          }
        }
      }

      userRecordsToInsert.add({
        'user_id': authIdByEmail[email] ?? email,
        'email': email,
        'name': name,
        'role': 'student',
      });
    }

    if (userRecordsToInsert.isNotEmpty) {
      try {
        final inserted = await _db.robleBulkInsert(
          RobleTables.users,
          userRecordsToInsert,
        );
        for (final row in inserted) {
          final email = normalizeEmail(_asString(row['email']));
          if (email.isNotEmpty) {
            usersByEmail[email] = row;
            final authId = _asString(row['user_id']);
            if (authId.isNotEmpty) authIdByEmail.putIfAbsent(email, () => authId);
          }
        }
      } catch (_) {
        // Fallback to individual creates if bulk fails.
        for (final record in userRecordsToInsert) {
          try {
            final row = await _db.robleCreate(RobleTables.users, record);
            final email = normalizeEmail(_asString(row['email']));
            if (email.isNotEmpty) {
              usersByEmail[email] = row;
              final authId = _asString(row['user_id']);
              if (authId.isNotEmpty) {
                authIdByEmail.putIfAbsent(email, () => authId);
              }
            }
          } catch (_) {}
        }
      }
    }

    // ── PHASE 3: Create category ─────────────────────────────────────────────
    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseReference,
    });
    final categoryReference = _categoryRef(catRow);
    final catId = _domainId(categoryReference, fallback: rowIdFromMap(catRow));

    // ── PHASE 4: Create groups + collect relation records ────────────────────
    final groups = <CourseGroup>[];
    final userGroupRecords = <Map<String, dynamic>>[];
    final userCourseRecords = <Map<String, dynamic>>[];

    for (final group in parsed.groups) {
      final grpRow = await _db.robleCreate(RobleTables.groups, {
        'category_id': categoryReference,
        'name': group.name,
      });
      final groupReference = _groupRef(grpRow);
      final grpId = _domainId(groupReference, fallback: rowIdFromMap(grpRow));

      final members = <GroupMember>[];
      for (final member in group.members) {
        final studentEmail = normalizeEmail(member.username);
        final userRow = usersByEmail[studentEmail];
        final userReference = _asString(userRow?['user_id']).isNotEmpty
            ? _asString(userRow!['user_id'])
            : (authIdByEmail[studentEmail] ?? studentEmail);
        final userId = _domainId(
          userReference,
          fallback: asInt(userRow?['id'] ?? userRow?['_id']),
        );

        if (hasUserGroupTable) {
          final ugKey = '$groupReference::$userReference';
          if (!existingUserGroupKeys.contains(ugKey)) {
            userGroupRecords.add({
              'group_id': groupReference,
              'user_id': userReference,
            });
            existingUserGroupKeys.add(ugKey);
          }
        }

        if (hasUserCourseTable) {
          final ucKey = '$courseReference::$userReference';
          if (!existingUserCourseKeys.contains(ucKey)) {
            userCourseRecords.add({
              'course_id': courseReference,
              'user_id': userReference,
              'role': 'student',
            });
            existingUserCourseKeys.add(ucKey);
          }
        }

        members.add(
          GroupMember(id: userId, name: member.name, username: studentEmail),
        );
      }

      groups.add(CourseGroup(id: grpId, name: group.name, members: members));
    }

    // ── PHASE 5: Bulk insert user_group ──────────────────────────────────────
    if (userGroupRecords.isNotEmpty) {
      try {
        await _db.robleBulkInsert(RobleTables.userGroup, userGroupRecords);
      } catch (_) {
        for (final record in userGroupRecords) {
          try {
            await _db.robleCreate(RobleTables.userGroup, record);
          } catch (_) {}
        }
      }
    }

    // ── PHASE 6: Bulk insert user_course ─────────────────────────────────────
    if (userCourseRecords.isNotEmpty) {
      try {
        await _db.robleBulkInsert(RobleTables.userCourse, userCourseRecords);
      } catch (_) {
        for (final record in userCourseRecords) {
          try {
            await _db.robleCreate(RobleTables.userCourse, record);
          } catch (_) {}
        }
      }
    }

    return GroupCategory(
      id: catId,
      name: categoryName,
      importedAt: DateTime.fromMillisecondsSinceEpoch(now),
      groups: groups,
      courseId: courseId,
    );
  }

  @override
  Future<void> delete(int categoryId) async {
    final catRows = await _db.robleRead(RobleTables.category);
    Map<String, dynamic>? target;
    String targetCatRef = '';
    for (final row in catRows) {
      final ref = _categoryRef(row);
      final domainId = _domainId(ref, fallback: rowIdFromMap(row));
      if (domainId == categoryId || rowIdFromMap(row) == categoryId) {
        target = row;
        targetCatRef = ref;
        break;
      }
    }
    if (target == null) return;
    if (targetCatRef.isEmpty) targetCatRef = categoryId.toString();

    var grpRows = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': targetCatRef},
    );
    if (grpRows.isEmpty) {
      grpRows = await _db.robleRead(
        RobleTables.groups,
        filters: {'category_id': categoryId.toString()},
      );
    }

    for (final grp in grpRows) {
      final groupRef = _groupRef(grp);
      final effectiveRef =
          groupRef.isNotEmpty ? groupRef : rowIdFromMap(grp).toString();
      final grpKey = grp['_id']?.toString();

      var memRows = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': effectiveRef},
      );
      if (memRows.isEmpty) {
        memRows = await _db.robleRead(
          RobleTables.userGroup,
          filters: {'group_id': rowIdFromMap(grp).toString()},
        );
      }

      for (final m in memRows) {
        final mk = m['_id']?.toString();
        if (mk != null && mk.isNotEmpty) {
          await _db.robleDelete(RobleTables.userGroup, mk);
        }
      }

      if (grpKey != null && grpKey.isNotEmpty) {
        await _db.robleDelete(RobleTables.groups, grpKey);
      }
    }

    final catKey = target['_id']?.toString();
    if (catKey != null && catKey.isNotEmpty) {
      await _db.robleDelete(RobleTables.category, catKey);
    }
  }

  // ─── Private: course ref resolution ─────────────────────────────────────

  String _resolveCourseRef(
    List<Map<String, dynamic>> courseRows,
    int courseId,
  ) {
    for (final row in courseRows) {
      final ref = _courseRef(row);
      if (ref.isEmpty) continue;
      final candidateIds = <int>{
        asInt(row['course_id'], fallback: -1),
        asInt(row['id'], fallback: -1),
        asInt(row['_id'], fallback: -1),
      };
      if (candidateIds.contains(courseId)) return ref;
    }
    return courseId.toString();
  }
}
```

---

# CAMBIO 5 — lib/domain/services/csv_import_domain_service.dart

**REEMPLAZA el archivo completo** con el siguiente contenido. Los cambios son: parser RFC-4180 para campos con comas, y preferencia por la columna `Email Address` (col 7) sobre `Username` (col 3):

```dart
class CsvImportParsedMember {
  final String name;
  final String username; // normalized email used as login

  const CsvImportParsedMember({
    required this.name,
    required this.username,
  });
}

class CsvImportParsedGroup {
  final String name;
  final List<CsvImportParsedMember> members;

  const CsvImportParsedGroup({
    required this.name,
    required this.members,
  });
}

class CsvImportParseResult {
  final List<CsvImportParsedGroup> groups;

  const CsvImportParseResult({required this.groups});

  int get totalGroups => groups.length;

  int get totalMembers =>
      groups.fold<int>(0, (sum, group) => sum + group.members.length);
}

class CsvImportDomainService {
  const CsvImportDomainService();

  CsvImportParseResult parse(String csvContent) {
    // Strip BOM if present.
    final content = csvContent.startsWith('\uFEFF')
        ? csvContent.substring(1)
        : csvContent;

    final lines = content
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) throw Exception('CSV vacío');

    final dataLines = lines.skip(1); // skip header row
    final groupsByName = <String, List<CsvImportParsedMember>>{};

    for (final line in dataLines) {
      // Use RFC-4180 compliant splitter to handle quoted commas.
      final columns = _splitCsvLine(line);
      if (columns.length < 7) continue;

      // Brightspace export format (9 columns):
      // 0 = Group Category Name
      // 1 = Group Name          ← used as group key
      // 2 = Group Code
      // 3 = Username            ← institutional email / login (fallback)
      // 4 = OrgDefinedId
      // 5 = First Name          ← used for display name
      // 6 = Last Name           ← used for display name
      // 7 = Email Address       ← preferred over Username when present
      // 8 = Group Enrollment Date
      final groupName = columns[1].trim();
      final username  = columns[3].trim().toLowerCase();
      final firstName = columns[5].trim();
      final lastName  = columns[6].trim();
      final emailCol  = columns.length > 7 ? columns[7].trim().toLowerCase() : '';

      // Prefer the explicit Email Address column (col 7); fall back to Username.
      final email    = emailCol.isNotEmpty ? emailCol : username;
      final fullName = '$firstName $lastName'.trim();

      if (groupName.isEmpty || email.isEmpty || fullName.isEmpty) continue;

      groupsByName
          .putIfAbsent(groupName, () => <CsvImportParsedMember>[])
          .add(CsvImportParsedMember(name: fullName, username: email));
    }

    if (groupsByName.isEmpty) throw Exception('Sin datos de grupos');

    final groups = groupsByName.entries
        .map(
          (entry) => CsvImportParsedGroup(
            name: entry.key,
            members: entry.value,
          ),
        )
        .toList(growable: false);

    return CsvImportParseResult(groups: groups);
  }

  /// RFC-4180 compliant CSV line splitter.
  ///
  /// Handles:
  ///   • Quoted fields containing commas: "Doe, Jane" → Doe, Jane
  ///   • Escaped double-quotes inside quoted fields: "" → "
  ///   • Unquoted fields
  List<String> _splitCsvLine(String line) {
    final result  = <String>[];
    final buffer  = StringBuffer();
    var inQuotes  = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        // Check for escaped quote ("" inside a quoted field).
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // consume the second quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString()); // last field
    return result;
  }
}
```

---

# VERIFICACIÓN FINAL

Después de aplicar todos los cambios:

1. Ejecuta `flutter pub get` para registrar la dependencia `http: ^1.6.0`
2. Ejecuta `flutter analyze` y corrige cualquier error de compilación que aparezca
3. Verifica que los siguientes archivos existen y NO fueron modificados:
   - `lib/data/services/database/database_service_auth.dart`
   - `lib/data/services/database/database_service_config.dart`
   - `lib/data/services/database/database_service_session.dart`
   - `lib/data/services/roble_schema.dart`
   - `lib/data/repositories/evaluation_repository_impl.dart`
   - `lib/data/repositories/course_repository_impl.dart`
   - `lib/data/repositories/auth_repository_impl.dart`
   - Todos los archivos en `lib/presentation/`
4. Confirma que `flutter analyze` termina sin errores

No hagas ningún cambio adicional fuera de los 5 archivos listados arriba.
