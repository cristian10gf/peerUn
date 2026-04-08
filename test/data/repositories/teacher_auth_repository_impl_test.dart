import 'package:example/data/repositories/teacher_auth_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTeacherAuthDatabaseService extends DatabaseService {
  Map<String, dynamic> loginResponse = <String, dynamic>{
    'accessToken': 'token-teacher',
    'refreshToken': 'refresh-teacher',
  };

  Map<String, dynamic>? userRow;
  Map<String, dynamic> jwtClaims = <String, dynamic>{
    'sub': '10',
    'role': 'teacher',
    'name': 'Teacher Name',
  };

  Map<String, dynamic>? teacherSession;
  Map<String, dynamic>? savedTeacherSession;
  Map<String, dynamic>? signupPayload;
  Map<String, dynamic>? createdUserPayload;
  Map<String, dynamic>? updatedUserPayload;

  String? updatedUserId;
  String? lastLoginEmail;
  String? sessionAccessToken;
  String? sessionRefreshToken;
  String? lastLogoutAccessToken;

  bool throwOnCreateUser = false;
  bool throwOnLogout = false;
  bool clearedTeacherSession = false;

  int createCalls = 0;
  int updateCalls = 0;

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
    teacherSession = Map<String, dynamic>.from(session);
  }

  @override
  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) async {
    signupPayload = <String, dynamic>{
      'email': email,
      'password': password,
      'name': name,
    };
    return <String, dynamic>{'ok': true};
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    createCalls++;
    createdUserPayload = Map<String, dynamic>.from(data);
    if (throwOnCreateUser) {
      throw Exception('duplicate-user');
    }
    return <String, dynamic>{'_id': 'users-1', ...data};
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    updateCalls++;
    updatedUserId = id.toString();
    updatedUserPayload = Map<String, dynamic>.from(updates);
    return <String, dynamic>{'_id': id.toString(), ...updates};
  }

  @override
  Future<Map<String, dynamic>?> readTeacherSession() async {
    if (teacherSession == null) {
      return null;
    }
    return Map<String, dynamic>.from(teacherSession!);
  }

  @override
  Future<void> robleLogout(String accessToken) async {
    lastLogoutAccessToken = accessToken;
    if (throwOnLogout) {
      throw Exception('logout-failed');
    }
  }

  @override
  Future<void> clearTeacherSession() async {
    clearedTeacherSession = true;
    teacherSession = null;
  }
}

void main() {
  test('login accepts admin role and persists teacher session', () async {
    final db = _FakeTeacherAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-10',
        'id': 10,
        'name': 'Admin Teacher',
        'email': 'admin@uninorte.edu.co',
        'role': 'admin',
      };

    final repo = TeacherAuthRepositoryImpl(db);
    final teacher = await repo.login('ADMIN@UNINORTE.EDU.CO', 'secret');

    expect(teacher, isNotNull);
    expect(teacher!.email, 'admin@uninorte.edu.co');
    expect(teacher.name, 'Admin Teacher');
    expect(teacher.initials, 'AT');
    expect(db.lastLoginEmail, 'admin@uninorte.edu.co');
    expect(db.savedTeacherSession?['role'], 'admin');
  });

  test('login returns null for non teacher roles', () async {
    final db = _FakeTeacherAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-21',
        'id': 21,
        'name': 'Student User',
        'email': 'student@uninorte.edu.co',
        'role': 'student',
      };

    final repo = TeacherAuthRepositoryImpl(db);
    final teacher = await repo.login('student@uninorte.edu.co', 'secret');

    expect(teacher, isNull);
    expect(db.savedTeacherSession, isNull);
  });

  test('register updates existing row when user sync create fails', () async {
    final db = _FakeTeacherAuthDatabaseService()
      ..throwOnCreateUser = true
      ..userRow = <String, dynamic>{
        '_id': 'users-existing-teacher',
        'id': 77,
        'name': 'Teacher Existing',
        'email': 'teacher@uninorte.edu.co',
        'role': 'teacher',
      }
      ..jwtClaims = <String, dynamic>{
        'sub': '77',
        'role': 'teacher',
        'name': 'Teacher Existing',
      };

    final repo = TeacherAuthRepositoryImpl(db);
    final teacher = await repo.register(
      ' Teacher Existing ',
      'TEACHER@UNINORTE.EDU.CO',
      'Password123!',
    );

    expect(teacher.email, 'teacher@uninorte.edu.co');
    expect(teacher.name, 'Teacher Existing');
    expect(db.createCalls, 1);
    expect(db.updateCalls, 1);
    expect(db.updatedUserId, 'users-existing-teacher');
    expect(db.updatedUserPayload?['role'], 'teacher');
    expect(db.signupPayload?['name'], 'Teacher Existing');
  });

  test('logout revokes teacher token and clears session', () async {
    final db = _FakeTeacherAuthDatabaseService()
      ..teacherSession = <String, dynamic>{
        'id': '9',
        'name': 'Prof',
        'email': 'prof@uninorte.edu.co',
        'initials': 'P',
        'access_token': 'token-prof',
        'refresh_token': 'refresh-prof',
      };

    final repo = TeacherAuthRepositoryImpl(db);
    await repo.logout();

    expect(db.lastLogoutAccessToken, 'token-prof');
    expect(db.clearedTeacherSession, isTrue);
  });

  test('getCurrentSession restores tokens and maps teacher payload', () async {
    final db = _FakeTeacherAuthDatabaseService()
      ..teacherSession = <String, dynamic>{
        'id': '33',
        'name': 'Teacher Session',
        'email': 'session@uninorte.edu.co',
        'initials': 'TS',
        'access_token': 'token-session',
        'refresh_token': 'refresh-session',
      };

    final repo = TeacherAuthRepositoryImpl(db);
    final session = await repo.getCurrentSession();

    expect(session, isNotNull);
    expect(session!.id, '33');
    expect(session.name, 'Teacher Session');
    expect(db.sessionAccessToken, 'token-session');
    expect(db.sessionRefreshToken, 'refresh-session');
  });
}
