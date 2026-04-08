/// Fake DatabaseService for Level-3 integration tests that exercise the
/// student evaluation submission chain:
///   Widget → StudentController → EvaluationRepositoryImpl → FakeDb
///
/// All table reads return deterministic fixture data.  The result tables
/// (resultEvaluation, result_criterium) start empty and accumulate records
/// through robleCreate calls, letting tests assert on what the real
/// repository actually wrote.
///
/// UUID design — all fixture UUIDs are numeric strings so that
/// DatabaseService.stableNumericIdFromSeed() returns the integer value
/// directly (it parses the string first before falling back to hashCode).
/// This makes domain-ID arithmetic predictable without having to compute
/// hashCodes in test code.
library;

import 'fake_database_service_level3.dart';

class FakeDatabaseServiceEvalLevel3 extends FakeDatabaseServiceLevel3 {
  // ── Fixture UUIDs / domain IDs ─────────────────────────────────────────────
  //   stableNumericIdFromSeed('100') = 100  (evaluation domain ID)
  //   stableNumericIdFromSeed('200') = 200  (category domain ID)
  //   stableNumericIdFromSeed('300') = 300  (student domain ID)
  //   stableNumericIdFromSeed('301') = 301  (peer 1 domain ID)
  //   stableNumericIdFromSeed('302') = 302  (peer 2 domain ID)
  //   stableNumericIdFromSeed('400') = 400  (group domain ID)
  //   stableNumericIdFromSeed('500') = 500  (course domain ID)

  // ── Mutable result tables (filled by robleCreate calls) ───────────────────
  final List<Map<String, dynamic>> createdResultEvals = [];
  final List<Map<String, dynamic>> createdResultCriteria = [];
  int _reCounter = 0;
  int _rcCounter = 0;

  // ── Fixture tables ─────────────────────────────────────────────────────────

  final _users = <Map<String, dynamic>>[
    {
      'user_id': '300',
      'id': '300',
      '_id': '300',
      'email': 'student@uni.edu',
      'username': 'student@uni.edu',
      'name': 'Ana López',
      'role': 'student',
    },
    {
      'user_id': '301',
      'id': '301',
      '_id': '301',
      'email': 'peer1@uni.edu',
      'username': 'peer1@uni.edu',
      'name': 'Bob Ruiz',
      'role': 'student',
    },
    {
      'user_id': '302',
      'id': '302',
      '_id': '302',
      'email': 'peer2@uni.edu',
      'username': 'peer2@uni.edu',
      'name': 'Carlos Vega',
      'role': 'student',
    },
  ];

  // evaluation.category_id stores the domain integer
  // stableNumericIdFromSeed('200') == 200.
  final _evaluations = <Map<String, dynamic>>[
    {
      'evaluation_id': '100',
      '_id': '100',
      'title': 'Test Eval',
      'category_id': 200,
      'description': 'private',
      'start_date': '2026-01-01T00:00:00.000Z',
      'end_date': '2099-01-01T00:00:00.000Z',
    },
  ];

  // category.category_id is the UUID string '200'.
  final _categories = <Map<String, dynamic>>[
    {
      'category_id': '200',
      '_id': '200',
      'name': 'Grupo IA',
      'course_id': '500',
    },
  ];

  // group.category_id is the UUID string '200' (not the domain int).
  final _groups = <Map<String, dynamic>>[
    {
      'group_id': '400',
      '_id': '400',
      'name': 'Equipo A',
      'category_id': '200',
    },
  ];

  final _userGroup = <Map<String, dynamic>>[
    {'_id': 'ug-1', 'group_id': '400', 'user_id': '300', 'email': 'student@uni.edu'},
    {'_id': 'ug-2', 'group_id': '400', 'user_id': '301', 'email': 'peer1@uni.edu'},
    {'_id': 'ug-3', 'group_id': '400', 'user_id': '302', 'email': 'peer2@uni.edu'},
  ];

  final _courses = <Map<String, dynamic>>[
    {'course_id': '500', '_id': '500', 'name': 'Fundamentos de IA'},
  ];

  final _userCourse = <Map<String, dynamic>>[
    {'_id': 'uc-1', 'course_id': '500', 'user_id': '300', 'role': 'student'},
  ];

  // Criterion names match EvalCriterion.defaults labels exactly so that
  // _getOrCreateCriteriaMap() finds them by label equality.
  final _criteria = <Map<String, dynamic>>[
    {'criterium_id': 'crit-1', '_id': 'crit-1', 'name': 'Puntualidad', 'max_score': 5},
    {'criterium_id': 'crit-2', '_id': 'crit-2', 'name': 'Contribuciones', 'max_score': 5},
    {'criterium_id': 'crit-3', '_id': 'crit-3', 'name': 'Compromiso', 'max_score': 5},
    {'criterium_id': 'crit-4', '_id': 'crit-4', 'name': 'Actitud', 'max_score': 5},
  ];

  // ── DatabaseService overrides ──────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final data = _tableData(tableName);
    if (filters == null || filters.isEmpty) return List.from(data);
    return data.where((row) {
      return filters.entries.every(
        (e) => row[e.key]?.toString() == e.value?.toString(),
      );
    }).toList();
  }

  List<Map<String, dynamic>> _tableData(String tableName) {
    return switch (tableName) {
      'user'                 => _users,
      'evaluation'           => _evaluations,
      'category'             => _categories,
      'group'                => _groups,
      'user_group'           => _userGroup,
      'course'               => _courses,
      'user_course'          => _userCourse,
      'criterium'            => _criteria,
      'resultEvaluation'     => createdResultEvals,
      'result_criterium'     => createdResultCriteria,
      'evaluation_criterium' => const <Map<String, dynamic>>[],
      _                      => const <Map<String, dynamic>>[],
    };
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final record = Map<String, dynamic>.from(data);
    if (tableName == 'resultEvaluation') {
      final uuid = 're-${++_reCounter}';
      record['resultEvaluation_id'] = uuid;
      record['_id'] = uuid;
      createdResultEvals.add(record);
      return record;
    }
    if (tableName == 'result_criterium') {
      final uuid = 'rc-${++_rcCounter}';
      record['_id'] = uuid;
      createdResultCriteria.add(record);
      return record;
    }
    if (tableName == 'criterium') {
      record['criterium_id'] = 'crit-new';
      record['_id'] = 'crit-new';
      return record;
    }
    record['_id'] = 'new-${tableName.hashCode}';
    return record;
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic key,
    Map<String, dynamic> data,
  ) async {
    if (tableName == 'result_criterium') {
      final idx = createdResultCriteria.indexWhere((r) => r['_id'] == key);
      if (idx != -1) {
        createdResultCriteria[idx] = {...createdResultCriteria[idx], ...data};
        return createdResultCriteria[idx];
      }
    }
    return <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> robleDelete(String tableName, dynamic key) async {
    // No-op — deletion is not under test here.
    return <String, dynamic>{};
  }

  @override
  Future<void> robleCreateTable(
    String tableName,
    List<Map<String, dynamic>> fields,
  ) async {
    // No-op — tables are simulated by the in-memory lists.
  }
}
