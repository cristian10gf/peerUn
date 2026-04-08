import 'package:example/data/services/database/database_service.dart';

class FakeDatabaseServiceLevel3 extends DatabaseService {
  Map<String, dynamic>? savedTeacherSession;
  Map<String, dynamic>? savedStudentSession;
  String? accessToken;
  String? refreshToken;

  @override
  Future<Map<String, dynamic>> robleLogin({
    required String email,
    required String password,
  }) async {
    return <String, dynamic>{
      'accessToken': 'token-teacher',
      'refreshToken': 'refresh-teacher',
    };
  }

  @override
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Map<String, dynamic> decodeJwtClaims(String accessToken) {
    return <String, dynamic>{
      'sub': '10',
      'role': 'teacher',
      'name': 'Teacher Integration',
      'email': 'teacher@uni.edu',
    };
  }

  @override
  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    if (email == 'teacher@uni.edu') {
      return <String, dynamic>{
        '_id': 'users-10',
        'id': 10,
        'name': 'Teacher Integration',
        'email': 'teacher@uni.edu',
        'role': 'teacher',
      };
    }
    return null;
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
    savedStudentSession = null;
  }

  @override
  Future<void> clearTeacherSession() async {
    savedTeacherSession = null;
  }

  @override
  Future<Map<String, dynamic>?> readTeacherSession() async {
    return savedTeacherSession;
  }

  @override
  Future<Map<String, dynamic>?> readStudentSession() async {
    return savedStudentSession;
  }
}
