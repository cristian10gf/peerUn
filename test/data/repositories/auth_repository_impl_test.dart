import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthDatabaseService extends DatabaseService {
  Map<String, dynamic> loginResponse = <String, dynamic>{
    'accessToken': 'token-student',
    'refreshToken': 'refresh-student',
  };

  Map<String, dynamic>? userRow;
  Map<String, dynamic> jwtClaims = <String, dynamic>{
    'sub': '22',
    'role': 'student',
    'name': 'Alice Lopez',
  };

  Map<String, dynamic>? studentSession;
  Map<String, dynamic>? savedStudentSession;
  Map<String, dynamic>? signupPayload;
  Map<String, dynamic>? createdUserPayload;
  Map<String, dynamic>? updatedUserPayload;

  String? updatedUserId;
  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastFindEmail;
  String? lastLogoutAccessToken;
  String? sessionAccessToken;
  String? sessionRefreshToken;

  bool throwOnFindUser = false;
  bool throwOnCreateUser = false;
  bool throwOnLogout = false;
  bool clearedStudentSession = false;

  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
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
    lastFindEmail = email;
    if (throwOnFindUser) {
      throw Exception('find-user-failed');
    }
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
  Future<void> saveStudentSession(Map<String, dynamic> session) async {
    savedStudentSession = Map<String, dynamic>.from(session);
    studentSession = Map<String, dynamic>.from(session);
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
  Future<Map<String, dynamic>?> readStudentSession() async {
    if (studentSession == null) {
      return null;
    }
    return Map<String, dynamic>.from(studentSession!);
  }

  @override
  Future<void> robleLogout(String accessToken) async {
    lastLogoutAccessToken = accessToken;
    if (throwOnLogout) {
      throw Exception('logout-failed');
    }
  }

  @override
  Future<void> clearStudentSession() async {
    clearedStudentSession = true;
    studentSession = null;
  }
}

void main() {
  test('login normalizes email and persists student session', () async {
    final db = _FakeAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-22',
        'id': 22,
        'name': 'Alice Lopez',
        'email': 'alice@uninorte.edu.co',
        'role': 'student',
      };

    final repo = AuthRepositoryImpl(db);
    final student = await repo.login('  ALICE@UNINORTE.EDU.CO ', 'secret');

    expect(student, isNotNull);
    expect(student!.email, 'alice@uninorte.edu.co');
    expect(student.name, 'Alice Lopez');
    expect(student.initials, 'AL');
    expect(db.lastLoginEmail, 'alice@uninorte.edu.co');
    expect(db.sessionAccessToken, 'token-student');
    expect(db.savedStudentSession?['role'], 'student');
    expect(db.savedStudentSession?['email'], 'alice@uninorte.edu.co');
  });

  test('login returns null when resolved role is not student', () async {
    final db = _FakeAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-10',
        'id': 10,
        'name': 'Teacher User',
        'email': 'teacher@uninorte.edu.co',
        'role': 'teacher',
      };

    final repo = AuthRepositoryImpl(db);
    final student = await repo.login('teacher@uninorte.edu.co', 'secret');

    expect(student, isNull);
    expect(db.savedStudentSession, isNull);
  });

  test('register updates existing row when create fails and then logs in', () async {
    final db = _FakeAuthDatabaseService()
      ..throwOnCreateUser = true
      ..userRow = <String, dynamic>{
        '_id': 'users-existing',
        'id': 55,
        'name': 'Bob Example',
        'email': 'bob@uninorte.edu.co',
        'role': 'student',
      }
      ..jwtClaims = <String, dynamic>{
        'sub': '55',
        'role': 'student',
        'name': 'Bob Example',
      };

    final repo = AuthRepositoryImpl(db);
    final student = await repo.register(
      ' Bob Example ',
      'BOB@UNINORTE.EDU.CO',
      'Password123!',
    );

    expect(student.email, 'bob@uninorte.edu.co');
    expect(student.name, 'Bob Example');
    expect(db.signupPayload?['name'], 'Bob Example');
    expect(db.signupPayload?['email'], 'bob@uninorte.edu.co');
    expect(db.createCalls, 1);
    expect(db.updateCalls, 1);
    expect(db.updatedUserId, 'users-existing');
    expect(db.updatedUserPayload?['role'], 'student');
    expect(db.updatedUserPayload?['email'], 'bob@uninorte.edu.co');
    expect(db.createdUserPayload?['role'], 'student');
    expect(db.createdUserPayload?['email'], 'bob@uninorte.edu.co');
  });

  test('logout revokes token when present and clears student session', () async {
    final db = _FakeAuthDatabaseService()
      ..studentSession = <String, dynamic>{
        'id': '1',
        'name': 'Alice',
        'email': 'alice@uninorte.edu.co',
        'initials': 'A',
        'access_token': 'token-abc',
        'refresh_token': 'refresh-abc',
      };

    final repo = AuthRepositoryImpl(db);
    await repo.logout();

    expect(db.lastLogoutAccessToken, 'token-abc');
    expect(db.clearedStudentSession, isTrue);
  });

  test('getCurrentSession restores tokens and maps student payload', () async {
    final db = _FakeAuthDatabaseService()
      ..studentSession = <String, dynamic>{
        'id': '7',
        'name': 'Student Session',
        'email': 'session@uninorte.edu.co',
        'initials': 'SS',
        'access_token': 'token-session',
        'refresh_token': 'refresh-session',
      };

    final repo = AuthRepositoryImpl(db);
    final session = await repo.getCurrentSession();

    expect(session, isNotNull);
    expect(session!.id, '7');
    expect(session.name, 'Student Session');
    expect(db.sessionAccessToken, 'token-session');
    expect(db.sessionRefreshToken, 'refresh-session');
  });

  test('register throws when users sync fails without existing key', () async {
    final db = _FakeAuthDatabaseService()
      ..throwOnCreateUser = true
      ..userRow = <String, dynamic>{
        'id': 88,
        'email': 'no-key@uninorte.edu.co',
        'name': 'No Key',
        'role': 'student',
      };

    final repo = AuthRepositoryImpl(db);

    expect(
      () => repo.register('No Key', 'no-key@uninorte.edu.co', 'secret'),
      throwsA(isA<Exception>()),
    );
  });

  test('register writes user payload to canonical users table', () async {
    final db = _FakeAuthDatabaseService()
      ..userRow = <String, dynamic>{
        '_id': 'users-new',
        'id': 11,
        'name': 'New User',
        'email': 'new@uninorte.edu.co',
        'role': 'student',
      };

    final repo = AuthRepositoryImpl(db);
    await repo.register('New User', 'new@uninorte.edu.co', 'secret');

    expect(db.createCalls, 1);
    expect(db.updateCalls, 0);
    expect(db.createdUserPayload, isNotNull);
    expect(db.createdUserPayload?['role'], 'student');
    expect(RobleTables.users, 'user');
  });
}
