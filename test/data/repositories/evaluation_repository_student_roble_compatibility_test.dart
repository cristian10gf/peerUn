import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudentEvaluationDatabaseService extends DatabaseService {
  final Map<String, List<Map<String, dynamic>>> _tables;

  _FakeStudentEvaluationDatabaseService(
    Map<String, List<Map<String, dynamic>>> tables,
  ) : _tables = tables;

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final source = (_tables[tableName] ?? const <Map<String, dynamic>>[])
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);

    if (filters == null || filters.isEmpty) {
      return source;
    }

    return source
        .where((row) {
          for (final entry in filters.entries) {
            if ((row[entry.key] ?? '').toString() != entry.value.toString()) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }
}

void main() {
  test(
    'getEvaluationsForStudent resolves group membership by group_id and maps modern evaluation fields',
    () async {
      final startsAt = DateTime(2026, 3, 28, 10);
      final closesAt = startsAt.add(const Duration(hours: 48));

      final db = _FakeStudentEvaluationDatabaseService({
        RobleTables.userGroup: [
          {
            '_id': 'membership-a',
            'id': 1001,
            'group_id': 10,
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
          },
        ],
        RobleTables.groups: [
          {'_id': 'group-a', 'id': 10, 'name': 'Equipo A', 'category_id': 7},
        ],
        RobleTables.category: [
          {'_id': 'cat-7', 'id': 7, 'name': 'Sprint 1', 'course_id': 3},
        ],
        RobleTables.course: [
          {'_id': 'course-3', 'id': 3, 'name': 'Arquitectura de Software'},
        ],
        RobleTables.evaluation: [
          {
            '_id': 'eval-77',
            'id': 77,
            'title': 'Evaluacion Sprint 1',
            'category_id': 7,
            'start_date': startsAt.millisecondsSinceEpoch,
            'end_date': closesAt.millisecondsSinceEpoch,
            'description': 'public',
          },
        ],
      });

      final repo = EvaluationRepositoryImpl(db);

      final evaluations = await repo.getEvaluationsForStudent(
        'alice@uninorte.edu.co',
      );

      expect(evaluations.length, 1);
      expect(evaluations.first.id, 77);
      expect(evaluations.first.name, 'Evaluacion Sprint 1');
      expect(evaluations.first.categoryName, 'Sprint 1');
      expect(evaluations.first.courseName, 'Arquitectura de Software');
      expect(evaluations.first.visibility, 'public');
      expect(evaluations.first.hours, 48);
    },
  );

  test(
    'getPeersForStudent supports group membership rows keyed by email',
    () async {
      final db = _FakeStudentEvaluationDatabaseService({
        RobleTables.evaluation: [
          {
            '_id': 'eval-77',
            'id': 77,
            'title': 'Evaluacion Sprint 1',
            'category_id': 7,
            'start_date': DateTime(2026, 3, 28, 10).millisecondsSinceEpoch,
            'end_date': DateTime(2026, 3, 30, 10).millisecondsSinceEpoch,
            'description': 'private',
          },
        ],
        RobleTables.groups: [
          {'_id': 'group-a', 'id': 10, 'name': 'Equipo A', 'category_id': 7},
        ],
        RobleTables.userGroup: [
          {
            '_id': 'membership-a',
            'id': 501,
            'group_id': 10,
            'email': 'alice@uninorte.edu.co',
            'name': 'Alice',
          },
          {
            '_id': 'membership-b',
            'id': 502,
            'group_id': 10,
            'email': 'bob@uninorte.edu.co',
            'name': 'Bob',
          },
        ],
      });

      final repo = EvaluationRepositoryImpl(db);

      final peers = await repo.getPeersForStudent(77, 'alice@uninorte.edu.co');

      expect(peers.length, 1);
      expect(peers.first.id, '502');
      expect(peers.first.name, 'Bob');
    },
  );

  test(
    'getStudentHomeCourses detects active evaluations using modern start/end fields and title',
    () async {
      final startsAt = DateTime.now().subtract(const Duration(hours: 1));
      final closesAt = DateTime.now().add(const Duration(hours: 6));

      final db = _FakeStudentEvaluationDatabaseService({
        RobleTables.users: [
          {
            '_id': 'user-alice',
            'id': 42,
            'user_id': '42',
            'name': 'Alice',
            'email': 'alice@uninorte.edu.co',
            'role': 'student',
          },
          {
            '_id': 'user-bob',
            'id': 50,
            'user_id': '50',
            'name': 'Bob',
            'email': 'bob@uninorte.edu.co',
            'role': 'student',
          },
        ],
        RobleTables.userCourse: [
          {
            '_id': 'uc-1',
            'id': 100,
            'course_id': 3,
            'email': 'alice@uninorte.edu.co',
            'role': 'student',
          },
        ],
        RobleTables.course: [
          {'_id': 'course-3', 'id': 3, 'name': 'Arquitectura de Software'},
        ],
        RobleTables.category: [
          {'_id': 'cat-7', 'id': 7, 'name': 'Sprint 1', 'course_id': 3},
        ],
        RobleTables.groups: [
          {'_id': 'group-a', 'id': 10, 'name': 'Equipo A', 'category_id': 7},
        ],
        RobleTables.userGroup: [
          {
            '_id': 'membership-a',
            'id': 501,
            'group_id': 10,
            'email': 'alice@uninorte.edu.co',
            'user_id': '42',
            'name': 'Alice',
          },
          {
            '_id': 'membership-b',
            'id': 502,
            'group_id': 10,
            'email': 'bob@uninorte.edu.co',
            'user_id': '50',
            'name': 'Bob',
          },
        ],
        RobleTables.evaluation: [
          {
            '_id': 'eval-77',
            'id': 77,
            'title': 'Evaluacion Sprint 1',
            'category_id': 7,
            'start_date': startsAt.millisecondsSinceEpoch,
            'end_date': closesAt.millisecondsSinceEpoch,
            'description': 'public',
          },
        ],
        RobleTables.evaluationCriterium: [
          {
            '_id': 'resp-1',
            'id': 900,
            'eval_id': 77,
            'evaluator_id': 42,
            'evaluated_member_id': 502,
            'criterion_id': 'punct',
            'score': 5,
          },
        ],
      });

      final repo = EvaluationRepositoryImpl(db);

      final courses = await repo.getStudentHomeCourses('alice@uninorte.edu.co');

      expect(courses.length, 1);
      expect(courses.first.name, 'Arquitectura de Software');
      expect(courses.first.categories.length, 1);

      final category = courses.first.categories.first;
      expect(category.hasActiveEvaluation, isTrue);
      expect(category.activeEvaluationId, 77);
      expect(category.activeEvaluationName, 'Evaluacion Sprint 1');
      expect(category.completedPeerCount, 1);
      expect(category.totalPeerCount, 1);
    },
  );
}
