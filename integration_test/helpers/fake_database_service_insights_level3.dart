library;

import 'fake_database_service_level3.dart';

class FakeDatabaseServiceInsightsLevel3 extends FakeDatabaseServiceLevel3 {
  final Map<String, int> readCallsByTable = {};

  final _evaluations = <Map<String, dynamic>>[
    {
      'evaluation_id': '600',
      '_id': '600',
      'title': 'Eval Insights',
      'teacher_id': '10',
      'category_id': '700',
      'description': 'public',
      'start_date': '2026-01-01T00:00:00.000Z',
      'end_date': '2099-01-01T00:00:00.000Z',
    },
  ];

  final _categories = <Map<String, dynamic>>[
    {'category_id': '700', '_id': '700', 'name': 'Sprint 1', 'course_id': '800'},
  ];

  final _courses = <Map<String, dynamic>>[
    {'course_id': '800', '_id': '800', 'name': 'Ingeniería de Software'},
  ];

  final _groups = <Map<String, dynamic>>[
    {'group_id': '900', '_id': '900', 'name': 'Equipo Alpha', 'category_id': '700'},
  ];

  final _userGroup = <Map<String, dynamic>>[
    {'_id': 'ug-1', 'group_id': '900', 'user_id': '301', 'email': 'student-a@uni.edu'},
    {'_id': 'ug-2', 'group_id': '900', 'user_id': '302', 'email': 'student-b@uni.edu'},
  ];

  final _users = <Map<String, dynamic>>[
    {'user_id': '301', 'id': '301', '_id': '301', 'email': 'student-a@uni.edu', 'name': 'Ana Perez', 'role': 'student'},
    {'user_id': '302', 'id': '302', '_id': '302', 'email': 'student-b@uni.edu', 'name': 'Bob Ruiz', 'role': 'student'},
  ];

  final _resultEvals = <Map<String, dynamic>>[
    {'resultEvaluation_id': 're-600-1', '_id': 're-600-1', 'evaluation_id': '600', 'evaluator_id': '301', 'evaluated_id': '302', 'group_id': '900'},
  ];

  final _resultCriteria = <Map<String, dynamic>>[
    {'_id': 'rc-1', 'result_id': 're-600-1', 'criterium_id': 'crit-1', 'score': 5},
    {'_id': 'rc-2', 'result_id': 're-600-1', 'criterium_id': 'crit-2', 'score': 4},
    {'_id': 'rc-3', 'result_id': 're-600-1', 'criterium_id': 'crit-3', 'score': 5},
    {'_id': 'rc-4', 'result_id': 're-600-1', 'criterium_id': 'crit-4', 'score': 4},
  ];

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    readCallsByTable[tableName] = (readCallsByTable[tableName] ?? 0) + 1;
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
      'evaluation'       => _evaluations,
      'category'         => _categories,
      'course'           => _courses,
      'group'            => _groups,
      'user_group'       => _userGroup,
      'user'             => _users,
      'resultEvaluation' => _resultEvals,
      'result_criterium' => _resultCriteria,
      _                  => const <Map<String, dynamic>>[],
    };
  }
}
