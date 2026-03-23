import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';

class UnifiedAuthRepositoryImpl implements IUnifiedAuthRepository {
  final DatabaseService _db;

  UnifiedAuthRepositoryImpl(this._db);

  static String _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _displayNameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'User';
    return local
        .split(RegExp(r'[._-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1))
        .join(' ');
  }

  @override
  Future<AuthLoginResult?> loginAndResolve(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();

    final auth = await _db.robleLogin(
      email: normalizedEmail,
      password: password,
    );

    final accessToken = (auth['accessToken'] ?? '').toString();
    final refreshToken = (auth['refreshToken'] ?? '').toString();
    if (accessToken.isEmpty) return null;

    _db.setSessionTokens(accessToken: accessToken, refreshToken: refreshToken);

    Map<String, dynamic>? userRow;
    try {
      userRow = await _db.robleFindUserByEmail(normalizedEmail);
    } catch (_) {
      // Keep login available while users table permissions are being configured.
    }

    final claims = _db.decodeJwtClaims(accessToken);
    final fallbackRole = (claims['role'] ?? '').toString().trim().toLowerCase();
    final role = (userRow?['role'] ?? fallbackRole).toString().trim().toLowerCase();
    final idSeed =
        (userRow?['id'] ?? userRow?['_id'] ?? claims['sub'] ?? normalizedEmail)
            .toString();
    final userId = DatabaseService.stableNumericIdFromSeed(idSeed).toString();
    final name =
        (userRow?['name'] ?? claims['name'] ?? _displayNameFromEmail(normalizedEmail))
            .toString();
    final initials = _buildInitials(name);

    if (role == 'teacher' || role == 'admin') {
      await _db.clearStudentSession();
      await _db.saveTeacherSession({
        'id': userId,
        'name': name,
        'email': normalizedEmail,
        'initials': initials,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'role': role,
      });
      return const AuthLoginResult(role: AppUserRole.teacher);
    }

    if (role == 'student') {
      await _db.clearTeacherSession();
      await _db.saveStudentSession({
        'id': userId,
        'name': name,
        'email': normalizedEmail,
        'initials': initials,
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'role': role,
      });
      return const AuthLoginResult(role: AppUserRole.student);
    }

    return null;
  }
}
