import 'package:example/data/services/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';

class TeacherAuthRepositoryImpl implements ITeacherAuthRepository {
  final DatabaseService _db;
  TeacherAuthRepositoryImpl(this._db);

  static String _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _displayNameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Teacher';
    return local
        .split(RegExp(r'[._-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

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

    final name = (userRow?['name'] ?? claims['name'] ?? _displayNameFromEmail(normalized))
        .toString();
    final teacher = Teacher(
      id: id,
      name: name,
      email: normalized,
      initials: _buildInitials(name),
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

    final userPayload = {
      'name': cleanName,
      'email': normalized,
      'role': 'teacher',
    };

    try {
      await _db.robleCreate(RobleTables.users, userPayload);
    } catch (e) {
      final existing = await _db.robleFindUserByEmail(normalized);
      final key = existing?['_id']?.toString() ?? '';
      if (key.isNotEmpty) {
        await _db.robleUpdate(RobleTables.users, key, userPayload);
      } else {
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
