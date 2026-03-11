import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';

class UnifiedAuthRepositoryImpl implements IUnifiedAuthRepository {
  final IAuthRepository _studentAuth;
  final ITeacherAuthRepository _teacherAuth;

  UnifiedAuthRepositoryImpl(this._studentAuth, this._teacherAuth);

  @override
  Future<AuthLoginResult?> loginAndResolve(
    String email,
    String password,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();

    final teacher = await _teacherAuth.login(normalizedEmail, password);
    if (teacher != null) {
      // Keep a single active role session.
      await _studentAuth.logout();
      return const AuthLoginResult(role: AppUserRole.teacher);
    }

    final student = await _studentAuth.login(normalizedEmail, password);
    if (student != null) {
      // Keep a single active role session.
      await _teacherAuth.logout();
      return const AuthLoginResult(role: AppUserRole.student);
    }

    return null;
  }
}
