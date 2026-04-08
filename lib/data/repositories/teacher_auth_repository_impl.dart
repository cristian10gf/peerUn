import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/string_utils.dart';
import 'package:example/data/utils/user_utils.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';

class TeacherAuthRepositoryImpl implements ITeacherAuthRepository {
  final DatabaseService _db;
  TeacherAuthRepositoryImpl(this._db);

  @override
  Future<Teacher?> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final auth = await _db.robleLogin(email: normalized, password: password);

    final accessToken = (auth['accessToken'] ?? '').toString();
    final refreshToken = (auth['refreshToken'] ?? '').toString();
    if (accessToken.isEmpty) return null;

    _db.setSessionTokens(accessToken: accessToken, refreshToken: refreshToken);

    Map<String, dynamic>? userRow;
    try {
      userRow = await _db.robleFindUserByEmail(normalized);
    } catch (_) {
      // Keep login available while table permissions are being configured.
    }

    final claims = _db.decodeJwtClaims(accessToken);
    final fallbackRole = (claims['role'] ?? '').toString().trim().toLowerCase();
    final role = (userRow?['role'] ?? fallbackRole).toString().trim().toLowerCase();
    if (role != 'teacher' && role != 'admin') return null;

    final idSeed = (userRow?['id'] ?? userRow?['_id'] ?? claims['sub'] ?? normalized)
        .toString();
    final id = DatabaseService.stableNumericIdFromSeed(idSeed).toString();

    final name = (userRow?['name'] ??
        claims['name'] ??
        buildDisplayNameFromEmail(normalized, fallback: 'Teacher'))
        .toString();
    final teacher = Teacher(
      id: id,
      name: name,
      email: normalized,
      initials: buildInitials(name),
    );

    await _db.saveTeacherSession({
      'id': teacher.id,
      'name': teacher.name,
      'email': teacher.email,
      'initials': teacher.initials,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'role': role,
    });

    return teacher;
  }

  @override
  Future<Teacher> register(String name, String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final cleanName = name.trim();

    await _db.robleSignupDirect(
      email: normalized,
      password: password,
      name: cleanName,
    );

    // Create/sync user profile row used by app role resolution.
    final auth = await _db.robleLogin(email: normalized, password: password);
    final accessToken = (auth['accessToken'] ?? '').toString();
    final refreshToken = (auth['refreshToken'] ?? '').toString();
    if (accessToken.isNotEmpty) {
      _db.setSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    // After login we have a valid JWT — extract sub to use as canonical user_id.
    final jwtClaims = _db.decodeJwtClaims(accessToken);
    final authUserId = (jwtClaims['sub'] ?? '').toString().trim();

    final userPayload = {
      if (authUserId.isNotEmpty) 'user_id': authUserId,
      'name': cleanName,
      'email': normalized,
      'role': 'teacher',
    };

    // READ-FIRST: avoid creating a duplicate user row when Roble's robleSignupDirect
    // may have already auto-created one, or when the user re-registers.
    List<Map<String, dynamic>> allUsers;
    try {
      allUsers = await _db.robleRead(RobleTables.users);
    } catch (_) {
      allUsers = const [];
    }

    Map<String, dynamic>? existingRow;
    for (final row in allUsers) {
      final rowUserId = row['user_id']?.toString() ?? '';
      if (authUserId.isNotEmpty && rowUserId == authUserId) {
        existingRow = row;
        break;
      }
    }
    if (existingRow == null) {
      for (final row in allUsers) {
        final rowEmail = (row['email'] ?? '').toString().trim().toLowerCase();
        if (rowEmail == normalized) {
          existingRow = row;
          break;
        }
      }
    }

    if (existingRow != null) {
      final key = existingRow['_id']?.toString() ?? '';
      if (key.isNotEmpty) {
        try {
          await _db.robleUpdate(RobleTables.users, key, userPayload);
        } catch (_) {
          // best-effort; login will still work
        }
      }
    } else {
      try {
        await _db.robleCreate(RobleTables.users, userPayload);
      } catch (e) {
        throw Exception(
          'Registro en auth completado, pero no se pudo sincronizar users: $e',
        );
      }
    }

    final logged = await login(normalized, password);
    if (logged == null) {
      throw Exception('No se pudo iniciar sesión tras el registro');
    }
    return logged;
  }

  @override
  Future<void> logout() async {
    final session = await _db.readTeacherSession();
    final accessToken = session?['access_token']?.toString();
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _db.robleLogout(accessToken);
      } catch (_) {}
    }
    await _db.clearTeacherSession();
  }

  @override
  Future<Teacher?> getCurrentSession() async {
    final session = await _db.readTeacherSession();
    if (session == null) return null;

    final accessToken = session['access_token']?.toString() ?? '';
    final refreshToken = session['refresh_token']?.toString() ?? '';
    if (accessToken.isNotEmpty) {
      _db.setSessionTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    return Teacher(
      id: session['id']?.toString() ?? '',
      name: session['name']?.toString() ?? '',
      email: session['email']?.toString() ?? '',
      initials: session['initials']?.toString() ?? '?',
    );
  }
}
