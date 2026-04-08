// test/data/services/database/database_service_session_test.dart
import 'package:example/data/services/database/database_service_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _studentKey = 'session_student';
const _teacherKey = 'session_teacher';

DatabaseServiceSession _makeSession() => DatabaseServiceSession(
      studentSessionKey: _studentKey,
      teacherSessionKey: _teacherKey,
      saveAuthTokens: ({
        required String accessToken,
        required String refreshToken,
        String? role,
      }) async {},
      clearAuthTokens: () async {},
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DatabaseServiceSession isolation', () {
    test('saveStudentSession clears any existing teacher session key', () async {
      // Pre-seed a teacher session.
      SharedPreferences.setMockInitialValues({
        _teacherKey: '{"name":"teacher"}',
      });

      final session = _makeSession();
      await session.saveStudentSession({
        'access_token': 'tok',
        'refresh_token': 'ref',
      });

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(_teacherKey),
        isNull,
        reason: 'Teacher session must be cleared when student session is saved',
      );
      expect(prefs.getString(_studentKey), isNotNull);
    });

    test('saveTeacherSession clears any existing student session key', () async {
      // Pre-seed a student session.
      SharedPreferences.setMockInitialValues({
        _studentKey: '{"name":"student"}',
      });

      final session = _makeSession();
      await session.saveTeacherSession({
        'access_token': 'tok',
        'refresh_token': 'ref',
      });

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(_studentKey),
        isNull,
        reason: 'Student session must be cleared when teacher session is saved',
      );
      expect(prefs.getString(_teacherKey), isNotNull);
    });
  });
}
