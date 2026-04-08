import 'package:example/data/repositories/unified_auth_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUnifiedAuthDatabaseService extends DatabaseService {
  Map<String, dynamic> loginResponse = <String, dynamic>{
    'accessToken': 'token-user',
    'refreshToken': 'refresh-user',
  };

  Map<String, dynamic>? userRow;
  Map<String, dynamic> jwtClaims = <String, dynamic>{
    'sub': '90',
    'role': 'student',
    'name': 'Unified User',
  };

  Map<String, dynamic>? savedStudentSession;
  Map<String, dynamic>? savedTeacherSession;

  String? sessionAccessToken;
  String? sessionRefreshToken;

  bool clearedStudentSession = false;
  bool clearedTeacherSession = false;
  String? lastLoginEmail;

  @override
  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    return Map<String, dynamic>.from(loginResponse);
  }

  @override
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    sessionAccessToken = accessToken;
    sessionRefreshToken = refreshToken;
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    if (userRow == null) {
      return null;
    }
    return Map<String, dynamic>.from(userRow!);
  }

  @override
  Map<String, dynamic> decodeJwtClaims(String accessToken) {
    return Map<String, dynamic>.from(jwtClaims);
  }

  @override
  Future<void> saveTeacherSession(Map<String, dynamic> session) async {
    savedTeacherSession = Map<String, dynamic>.from(session);
  }

  @override
  Future<void> saveStudentSession(Map<String, dynamic> session) async {
    savedStudentSession = Map<String, dynamic>.from(session);
  }

  @override
  Future<void> clearStudentSession() async {
    clearedStudentSession = true;
    savedStudentSession = null;
  }

  @override
  Future<void> clearTeacherSession() async {
    clearedTeacherSession = true;
    savedTeacherSession = null;
  }
}

void main() {
  test('loginAndResolve routes teacher/admin users to teacher session', () async {
    final db = _FakeUnifiedAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-5',
        'id': 5,
        'name': 'Professor Admin',
        'email': 'admin@uninorte.edu.co',
        'role': 'admin',
      };

    final repo = UnifiedAuthRepositoryImpl(db);
    final result = await repo.loginAndResolve(' ADMIN@UNINORTE.EDU.CO ', 'pw');

    expect(result, isNotNull);
    expect(result!.role, AppUserRole.teacher);
    expect(db.lastLoginEmail, 'admin@uninorte.edu.co');
    expect(db.clearedStudentSession, isTrue);
    expect(db.clearedTeacherSession, isFalse);
    expect(db.savedTeacherSession?['role'], 'admin');
    expect(db.savedTeacherSession?['email'], 'admin@uninorte.edu.co');
  });

  test('loginAndResolve routes student users to student session', () async {
    final db = _FakeUnifiedAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-8',
        'id': 8,
        'name': 'Student Unified',
        'email': 'student@uninorte.edu.co',
        'role': 'student',
      };

    final repo = UnifiedAuthRepositoryImpl(db);
    final result = await repo.loginAndResolve('student@uninorte.edu.co', 'pw');

    expect(result, isNotNull);
    expect(result!.role, AppUserRole.student);
    expect(db.clearedTeacherSession, isTrue);
    expect(db.clearedStudentSession, isFalse);
    expect(db.savedStudentSession?['role'], 'student');
    expect(db.savedStudentSession?['email'], 'student@uninorte.edu.co');
  });

  test('loginAndResolve returns null when access token is empty', () async {
    final db = _FakeUnifiedAuthDatabaseService()
      ..loginResponse = <String, dynamic>{
        'accessToken': '',
        'refreshToken': 'refresh',
      };

    final repo = UnifiedAuthRepositoryImpl(db);
    final result = await repo.loginAndResolve('any@uninorte.edu.co', 'pw');

    expect(result, isNull);
    expect(db.savedTeacherSession, isNull);
    expect(db.savedStudentSession, isNull);
  });

  test('loginAndResolve uses JWT fallback role when users row is unavailable', () async {
    final db = _FakeUnifiedAuthDatabaseService()
      ..userRow = null
      ..jwtClaims = <String, dynamic>{
        'sub': '111',
        'role': 'teacher',
        'name': 'Jwt Teacher',
      };

    final repo = UnifiedAuthRepositoryImpl(db);
    final result = await repo.loginAndResolve('jwt@uninorte.edu.co', 'pw');

    expect(result, isNotNull);
    expect(result!.role, AppUserRole.teacher);
    expect(db.savedTeacherSession?['name'], 'Jwt Teacher');
  });

  test('loginAndResolve returns null when role cannot be resolved', () async {
    final db = _FakeUnifiedAuthDatabaseService()
      ..userRow = null
      ..jwtClaims = <String, dynamic>{
        'sub': '111',
        'role': 'guest',
        'name': 'Guest User',
      };

    final repo = UnifiedAuthRepositoryImpl(db);
    final result = await repo.loginAndResolve('guest@uninorte.edu.co', 'pw');

    expect(result, isNull);
    expect(db.savedTeacherSession, isNull);
    expect(db.savedStudentSession, isNull);
  });
}
