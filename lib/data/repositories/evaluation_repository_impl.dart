import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/string_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final DatabaseService _db;
  EvaluationRepositoryImpl(this._db);

  int _asInt(dynamic value, {int fallback = 0}) =>
      asInt(value, fallback: fallback);

  double _asDouble(dynamic value, {double fallback = 0}) =>
      asDouble(value, fallback: fallback);

  String _asString(dynamic value) => asString(value);

  int _rowId(Map<String, dynamic> row) => rowIdFromMap(row);

  DateTime _asDate(dynamic value) => asDate(value);

  Map<String, dynamic>? _findById(List<Map<String, dynamic>> rows, int id) {
    for (final row in rows) {
      if (_rowId(row) == id) return row;
    }
    return null;
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  @override
  Future<Evaluation> create({
    required String name,
    required int categoryId,
    required int hours,
    required String visibility,
    required int teacherId,
  }) async {
    final existing = await _db.robleRead(
      RobleTables.evaluation,
      filters: {'teacher_id': teacherId},
    );
    final duplicate = existing.any(
      (r) => _asString(r['name']).toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('Ya existe una evaluación con ese nombre');
    }

    final now = DateTime.now();
    final closesAt = now.add(Duration(hours: hours));

    final row = await _db.robleCreate(RobleTables.evaluation, {
      'name': name,
      'category_id': categoryId,
      'hours': hours,
      'visibility': visibility,
      'created_at': now.millisecondsSinceEpoch,
      'closes_at': closesAt.millisecondsSinceEpoch,
      'teacher_id': teacherId,
    });

    final catRows = await _db.robleRead(
      RobleTables.category,
      filters: {'id': categoryId},
    );
    final catName = catRows.isNotEmpty ? _asString(catRows.first['name']) : '';

    return Evaluation(
      id: _rowId(row),
      name: _asString(row['name']).isEmpty ? name : _asString(row['name']),
      categoryId: _asInt(row['category_id'], fallback: categoryId),
      categoryName: catName,
      hours: _asInt(row['hours'], fallback: hours),
      visibility: _asString(row['visibility']).isEmpty ? visibility : _asString(row['visibility']),
      createdAt: _asDate(row['created_at'] ?? now.millisecondsSinceEpoch),
      closesAt: _asDate(row['closes_at'] ?? closesAt.millisecondsSinceEpoch),
    );
  }

  // ── All evaluations ────────────────────────────────────────────────────────

  @override
  Future<List<Evaluation>> getAll(int teacherId) async {
    final evalRows = await _db.robleRead(
      RobleTables.evaluation,
      filters: {'teacher_id': teacherId},
    );
    final catRows = await _db.robleRead(RobleTables.category);
    final courseRows = await _db.robleRead(RobleTables.course);

    final courseById = <int, String>{};
    for (final c in courseRows) {
      courseById[_rowId(c)] = _asString(c['name']);
    }

    final catById = <int, Map<String, dynamic>>{};
    for (final c in catRows) {
      catById[_rowId(c)] = c;
    }

    final list = evalRows.map((row) {
      final catId = _asInt(row['category_id']);
      final cat = catById[catId];
      final courseName = cat == null ? '' : (courseById[_asInt(cat['course_id'])] ?? '');

      return Evaluation(
        id: _rowId(row),
        name: _asString(row['name']),
        categoryId: catId,
        categoryName: cat == null ? '' : _asString(cat['name']),
        courseName: courseName,
        hours: _asInt(row['hours']),
        visibility: _asString(row['visibility']),
        createdAt: _asDate(row['created_at']),
        closesAt: _asDate(row['closes_at']),
      );
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> rename(int evalId, String newName, int teacherId) async {
    final evalRows = await _db.robleRead(
      RobleTables.evaluation,
      filters: {'teacher_id': teacherId},
    );

    for (final row in evalRows) {
      if (_rowId(row) != evalId && _asString(row['name']).toLowerCase() == newName.toLowerCase()) {
        throw Exception('Ya existe una evaluación con ese nombre');
      }
    }

    final target = _findById(evalRows, evalId);
    final key = target?['_id']?.toString();
    if (key == null || key.isEmpty) {
      throw Exception('No se encontró la evaluación');
    }

    await _db.robleUpdate(RobleTables.evaluation, key, {'name': newName});
  }

  @override
  Future<void> delete(int evalId) async {
    final responseRows = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {'eval_id': evalId},
    );
    for (final row in responseRows) {
      final key = row['_id']?.toString();
      if (key != null && key.isNotEmpty) {
        await _db.robleDelete(RobleTables.evaluationCriterium, key);
      }
    }

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final target = _findById(evalRows, evalId);
    final evalKey = target?['_id']?.toString();
    if (evalKey != null && evalKey.isNotEmpty) {
      await _db.robleDelete(RobleTables.evaluation, evalKey);
    }
  }

  // ── Group results ──────────────────────────────────────────────────────────

  @override
  Future<List<GroupResult>> getGroupResults(int evalId) async {
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final groups = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );
    final responses = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {'eval_id': evalId},
    );

    final result = <GroupResult>[];
    const criterionIds = ['punct', 'contrib', 'commit', 'attitude'];

    for (final g in groups) {
      final gid = _rowId(g);
      final members = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': gid},
      );
      final memberIds = members.map(_rowId).toSet();

      final students = <StudentResult>[];
      for (final m in members) {
        final mid = _rowId(m);
        final mName = _asString(m['name']);

        final memberResponses = responses.where(
          (r) => _asInt(r['evaluated_member_id']) == mid && _asInt(r['score']) >= 2,
        );
        final values = memberResponses.map((r) => _asDouble(r['score'])).toList();

        final avg = values.isEmpty
            ? 0.0
            : double.parse((values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1));

        students.add(
          StudentResult(
            initial: mName.isNotEmpty ? mName[0].toUpperCase() : '?',
            name: mName,
            score: avg,
          ),
        );
      }

      final criteria = <double>[];
      for (final cid in criterionIds) {
        final cResponses = responses.where(
          (r) => memberIds.contains(_asInt(r['evaluated_member_id'])) &&
              _asString(r['criterion_id']) == cid &&
              _asInt(r['score']) >= 2,
        );
        final values = cResponses.map((r) => _asDouble(r['score'])).toList();
        final avg = values.isEmpty
            ? 0.0
            : double.parse((values.reduce((a, b) => a + b) / values.length).toStringAsFixed(1));
        criteria.add(avg);
      }

      final validScores = students.where((s) => s.score > 0).map((s) => s.score).toList();
      final groupAvg = validScores.isEmpty
          ? 0.0
          : double.parse(
              (validScores.reduce((a, b) => a + b) / validScores.length)
                  .toStringAsFixed(1),
            );

      result.add(
        GroupResult(
          name: _asString(g['name']),
          average: groupAvg,
          criteria: criteria,
          students: students,
        ),
      );
    }

    return result;
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  @override
  Future<List<Evaluation>> getEvaluationsForStudent(String email) async {
    final normalized = email.toLowerCase();
    final members = await _db.robleRead(RobleTables.userGroup);
    final groups = await _db.robleRead(RobleTables.groups);
    final categories = await _db.robleRead(RobleTables.category);
    final courses = await _db.robleRead(RobleTables.course);
    final evals = await _db.robleRead(RobleTables.evaluation);

    final myGroupIds = members
        .where((m) => _asString(m['username']).toLowerCase() == normalized)
        .map(_rowId)
        .toSet();

    final myCategoryIds = groups
        .where((g) => myGroupIds.contains(_rowId(g)))
        .map((g) => _asInt(g['category_id']))
        .toSet();

    final catById = <int, Map<String, dynamic>>{};
    for (final c in categories) {
      catById[_rowId(c)] = c;
    }

    final courseById = <int, String>{};
    for (final c in courses) {
      courseById[_rowId(c)] = _asString(c['name']);
    }

    final list = evals
        .where((e) => myCategoryIds.contains(_asInt(e['category_id'])))
        .map((row) {
          final catId = _asInt(row['category_id']);
          final cat = catById[catId];
          final courseName = cat == null ? '' : (courseById[_asInt(cat['course_id'])] ?? '');
          return Evaluation(
            id: _rowId(row),
            name: _asString(row['name']),
            categoryId: catId,
            categoryName: cat == null ? '' : _asString(cat['name']),
            courseName: courseName,
            hours: _asInt(row['hours']),
            visibility: _asString(row['visibility']),
            createdAt: _asDate(row['created_at']),
            closesAt: _asDate(row['closes_at']),
          );
        })
        .toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Evaluation?> getLatestForStudent(String email) async {
    final list = await getEvaluationsForStudent(email);
    if (list.isEmpty) return null;
    return list.first;
  }

  @override
  Future<String?> getGroupNameForStudent(int evalId, String email) async {
    final normalized = email.toLowerCase();

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return null;

    final categoryId = _asInt(eval['category_id']);
    final groups = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );

    for (final g in groups) {
      final members = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': _rowId(g)},
      );
      final found = members.any((m) => _asString(m['username']).toLowerCase() == normalized);
      if (found) return _asString(g['name']);
    }

    return null;
  }

  @override
  Future<List<Peer>> getPeersForStudent(int evalId, String email) async {
    final normalized = email.toLowerCase();

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final groups = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );

    int? groupId;
    for (final g in groups) {
      final gid = _rowId(g);
      final members = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': gid},
      );
      final isInGroup = members.any((m) => _asString(m['username']).toLowerCase() == normalized);
      if (isInGroup) {
        groupId = gid;
        break;
      }
    }

    if (groupId == null) return [];

    final rows = await _db.robleRead(
      RobleTables.userGroup,
      filters: {'group_id': groupId},
    );
    return rows
        .where((m) => _asString(m['username']).toLowerCase() != normalized)
        .map((m) {
          final name = _asString(m['name']);
          return Peer(
            id: _rowId(m).toString(),
            name: name,
            initials: buildInitials(name),
          );
        })
        .toList();
  }

  @override
  Future<List<Course>> getCoursesForStudent(String email) async {
    final normalized = email.toLowerCase();
    final members = await _db.robleRead(RobleTables.userGroup);
    final groups = await _db.robleRead(RobleTables.groups);
    final categories = await _db.robleRead(RobleTables.category);

    final groupsById = <int, Map<String, dynamic>>{};
    for (final g in groups) {
      groupsById[_rowId(g)] = g;
    }

    final categoryById = <int, Map<String, dynamic>>{};
    for (final c in categories) {
      categoryById[_rowId(c)] = c;
    }

    final myMemberships = members
        .where((m) => _asString(m['username']).toLowerCase() == normalized)
        .toList();

    final result = <Course>[];
    for (final m in myMemberships) {
      final groupId = _asInt(m['group_id']);
      final group = groupsById[groupId];
      if (group == null) continue;

      final category = categoryById[_asInt(group['category_id'])];
      final memberCount = members.where((x) => _asInt(x['group_id']) == groupId).length;

      result.add(
        Course(
          id: groupId.toString(),
          name: category == null ? '' : _asString(category['name']),
          groupName: _asString(group['name']),
          memberCount: memberCount,
        ),
      );
    }

    return result;
  }

  // ── Responses ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveResponses({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
    required Map<String, int> scores,
  }) async {
    for (final entry in scores.entries) {
      await _db.robleCreate(RobleTables.evaluationCriterium, {
        'eval_id': evalId,
        'evaluator_id': evaluatorStudentId,
        'evaluated_member_id': evaluatedMemberId,
        'criterion_id': entry.key,
        'score': entry.value,
      });
    }
  }

  @override
  Future<bool> hasEvaluated({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
  }) async {
    final rows = await _db.robleRead(RobleTables.evaluationCriterium, filters: {
      'eval_id': evalId,
      'evaluator_id': evaluatorStudentId,
      'evaluated_member_id': evaluatedMemberId,
    });
    return rows.isNotEmpty;
  }

  @override
  Future<List<CriterionResult>> getMyResults(int evalId, String email) async {
    final normalized = email.toLowerCase();

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final groups = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );

    final myMemberIds = <int>{};
    for (final g in groups) {
      final gid = _rowId(g);
      final members = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': gid},
      );
      for (final m in members) {
        if (_asString(m['username']).toLowerCase() == normalized) {
          myMemberIds.add(_rowId(m));
        }
      }
    }

    if (myMemberIds.isEmpty) return [];

    final rows = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {'eval_id': evalId},
    );

    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final r in rows) {
      final targetId = _asInt(r['evaluated_member_id']);
      final score = _asInt(r['score']);
      if (!myMemberIds.contains(targetId) || score < 2) continue;

      final cid = _asString(r['criterion_id']);
      sums[cid] = (sums[cid] ?? 0) + score;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }

    return EvalCriterion.defaults.map((c) {
      final count = counts[c.id] ?? 0;
      final val = count == 0 ? 0.0 : (sums[c.id]! / count);
      return CriterionResult(
        label: c.label,
        value: double.parse(val.toStringAsFixed(1)),
      );
    }).toList();
  }

  @override
  Future<bool> hasCompletedAllPeers({
    required int evalId,
    required String email,
    required int studentId,
  }) async {
    final normalized = email.toLowerCase();

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return false;

    final categoryId = _asInt(eval['category_id']);
    final groups = await _db.robleRead(
      RobleTables.groups,
      filters: {'category_id': categoryId},
    );

    int? groupId;
    for (final g in groups) {
      final gid = _rowId(g);
      final members = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': gid},
      );
      final found = members.any((m) => _asString(m['username']).toLowerCase() == normalized);
      if (found) {
        groupId = gid;
        break;
      }
    }

    if (groupId == null) return false;

    final groupMembers = await _db.robleRead(
      RobleTables.userGroup,
      filters: {'group_id': groupId},
    );
    final peerIds = groupMembers
        .where((m) => _asString(m['username']).toLowerCase() != normalized)
        .map(_rowId)
        .toSet();

    if (peerIds.isEmpty) return false;

    final responses = await _db.robleRead(RobleTables.evaluationCriterium, filters: {
      'eval_id': evalId,
      'evaluator_id': studentId,
    });

    final doneIds = <int>{};
    for (final r in responses) {
      final target = _asInt(r['evaluated_member_id']);
      if (peerIds.contains(target)) doneIds.add(target);
    }

    return doneIds.length >= peerIds.length;
  }
}
