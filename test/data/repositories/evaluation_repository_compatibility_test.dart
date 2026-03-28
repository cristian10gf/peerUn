import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEvaluationDatabaseService extends DatabaseService {
  final List<Map<String, dynamic>> _evaluations;
  final List<Map<String, dynamic>> _categories;
  final List<Map<String, dynamic>> _courses;

  _FakeEvaluationDatabaseService({
    required List<Map<String, dynamic>> evaluations,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> courses,
  }) : _evaluations = evaluations,
       _categories = categories,
       _courses = courses;

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    late final List<Map<String, dynamic>> source;
    if (tableName == RobleTables.evaluation) {
      source = _evaluations;
    } else if (tableName == RobleTables.category) {
      source = _categories;
    } else if (tableName == RobleTables.course) {
      source = _courses;
    } else {
      source = const <Map<String, dynamic>>[];
    }

    if (filters == null || filters.isEmpty) {
      return source.map((row) => Map<String, dynamic>.from(row)).toList();
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
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (tableName != RobleTables.evaluation) {
      throw Exception('Unexpected create table: $tableName');
    }

    // Simulate current Roble schema where evaluation uses modern DBML fields.
    if (!data.containsKey('title') || !data.containsKey('created_by')) {
      throw Exception('column does not exist in table evaluation');
    }

    final row = <String, dynamic>{
      '_id': 'eval-1',
      'id': 1,
      'title': data['title'],
      'category_id': data['category_id'],
      'created_by': data['created_by'],
      'start_date': data['start_date'],
      'end_date': data['end_date'],
      'description': data['description'] ?? '',
    };
    _evaluations.add(row);
    return row;
  }
}

void main() {
  test('create supports modern Roble evaluation schema fields', () async {
    final db = _FakeEvaluationDatabaseService(
      evaluations: <Map<String, dynamic>>[],
      categories: <Map<String, dynamic>>[
        {'_id': 'cat-1', 'id': 7, 'name': 'Sprint 1', 'course_id': 3},
      ],
      courses: <Map<String, dynamic>>[
        {'_id': 'course-1', 'id': 3, 'name': 'Arquitectura de Software'},
      ],
    );

    final repo = EvaluationRepositoryImpl(db);

    final created = await repo.create(
      name: 'Evaluacion Sprint',
      categoryId: 7,
      hours: 24,
      visibility: 'private',
      teacherId: 42,
    );

    expect(created.name, 'Evaluacion Sprint');
    expect(created.categoryId, 7);
    expect(created.hours, greaterThan(0));
    expect(created.visibility, 'private');
  });

  test(
    'getAll maps modern Roble schema rows for teacher ownership and title fields',
    () async {
      final now = DateTime(2026, 3, 25, 10);
      final db = _FakeEvaluationDatabaseService(
        evaluations: <Map<String, dynamic>>[
          {
            '_id': 'eval-1',
            'id': 1,
            'title': 'Eval Visible',
            'category_id': 7,
            'created_by': 42,
            'start_date': now.millisecondsSinceEpoch,
            'end_date': now
                .add(const Duration(hours: 48))
                .millisecondsSinceEpoch,
            'description': 'public',
          },
          {
            '_id': 'eval-2',
            'id': 2,
            'title': 'Eval Otro Profe',
            'category_id': 7,
            'created_by': 999,
            'start_date': now.millisecondsSinceEpoch,
            'end_date': now
                .add(const Duration(hours: 24))
                .millisecondsSinceEpoch,
            'description': 'private',
          },
        ],
        categories: <Map<String, dynamic>>[
          {'_id': 'cat-1', 'id': 7, 'name': 'Sprint 1', 'course_id': 3},
        ],
        courses: <Map<String, dynamic>>[
          {'_id': 'course-1', 'id': 3, 'name': 'Arquitectura de Software'},
        ],
      );

      final repo = EvaluationRepositoryImpl(db);

      final evaluations = await repo.getAll(42);

      expect(evaluations.length, 1);
      expect(evaluations.first.name, 'Eval Visible');
      expect(evaluations.first.courseName, 'Arquitectura de Software');
      expect(evaluations.first.visibility, 'public');
      expect(evaluations.first.hours, 48);
    },
  );
}
