import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final DatabaseService _db;
  EvaluationRepositoryImpl(this._db);

  static String _buildInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  @override
  Future<Evaluation> create({
    required String name,
    required int categoryId,
    required int hours,
    required String visibility,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final closesAt = now.add(Duration(hours: hours));
    final id = await db.insert('evaluations', {
      'name':        name,
      'category_id': categoryId,
      'hours':       hours,
      'visibility':  visibility,
      'created_at':  now.millisecondsSinceEpoch,
      'closes_at':   closesAt.millisecondsSinceEpoch,
    });
    final catRows = await db.query('group_categories',
        where: 'id = ?', whereArgs: [categoryId]);
    final catName =
        catRows.isEmpty ? '' : catRows.first['name'] as String;
    return Evaluation(
      id:           id,
      name:         name,
      categoryId:   categoryId,
      categoryName: catName,
      hours:        hours,
      visibility:   visibility,
      createdAt:    now,
      closesAt:     closesAt,
    );
  }

  // ── All evaluations ────────────────────────────────────────────────────────

  @override
  Future<List<Evaluation>> getAll() async {
    final db   = await _db.database;
    final rows = await db.rawQuery('''
      SELECT e.*, gc.name AS category_name
      FROM evaluations e
      JOIN group_categories gc ON gc.id = e.category_id
      ORDER BY e.created_at DESC
    ''');
    return rows.map(_rowToEval).toList();
  }

  // ── Group results ──────────────────────────────────────────────────────────

  @override
  Future<List<GroupResult>> getGroupResults(int evalId) async {
    final db = await _db.database;

    // Per-member average scores
    final memberRows = await db.rawQuery('''
      SELECT g.id AS grp_id, g.name AS grp_name,
             gm.id AS mem_id, gm.name AS mem_name,
             COALESCE(
               AVG(CASE WHEN er.score >= 2 THEN CAST(er.score AS REAL) END),
               0.0
             ) AS avg_score
      FROM groups g
      JOIN evaluations e    ON e.category_id = g.category_id
      JOIN group_members gm ON gm.group_id = g.id
      LEFT JOIN evaluation_responses er
             ON er.eval_id = e.id
            AND er.evaluated_member_id = gm.id
            AND er.score >= 2
      WHERE e.id = ?
      GROUP BY g.id, gm.id
      ORDER BY g.name, gm.name
    ''', [evalId]);

    // Per-criterion averages per group
    final critRows = await db.rawQuery('''
      SELECT g.id AS grp_id, er.criterion_id,
             AVG(CAST(er.score AS REAL)) AS avg_score
      FROM groups g
      JOIN evaluations e    ON e.category_id = g.category_id
      JOIN group_members gm ON gm.group_id = g.id
      JOIN evaluation_responses er
             ON er.eval_id = e.id
            AND er.evaluated_member_id = gm.id
            AND er.score >= 2
      WHERE e.id = ?
      GROUP BY g.id, er.criterion_id
    ''', [evalId]);

    // Build criterion map: grp_id → { criterion_id → avg }
    final critMap = <int, Map<String, double>>{};
    for (final r in critRows) {
      final gid = r['grp_id'] as int;
      final cid = r['criterion_id'] as String;
      critMap.putIfAbsent(gid, () => <String, double>{})[cid] = r['avg_score'] as double;
    }

    // Group rows by group id
    final groupNames   = <int, String>{};
    final groupMembers = <int, List<Map<String, Object?>>>{};
    for (final r in memberRows) {
      final gid = r['grp_id'] as int;
      groupNames[gid] = r['grp_name'] as String;
      groupMembers.putIfAbsent(gid, () => []).add(r);
    }

    const criterionIds = ['punct', 'contrib', 'commit', 'attitude'];

    return groupNames.entries.map((entry) {
      final gid     = entry.key;
      final members = groupMembers[gid] ?? [];

      final students = members.map((m) {
        final name = m['mem_name'] as String;
        final avg  = m['avg_score'] as double;
        return StudentResult(
          initial: name.isNotEmpty ? name[0].toUpperCase() : '?',
          name:    name,
          score:   double.parse(avg.toStringAsFixed(1)),
        );
      }).toList();

      final cm       = critMap[gid] ?? {};
      final criteria = criterionIds.map((id) {
        final v = cm[id] ?? 0.0;
        return double.parse(v.toStringAsFixed(1));
      }).toList();

      final validScores = students
          .where((s) => s.score > 0)
          .map((s) => s.score)
          .toList();
      final average = validScores.isEmpty
          ? 0.0
          : double.parse(
              (validScores.reduce((a, b) => a + b) / validScores.length)
                  .toStringAsFixed(1));

      return GroupResult(
        name:     entry.value,
        average:  average,
        criteria: criteria,
        students: students,
      );
    }).toList();
  }

  // ── Queries ────────────────────────────────────────────────────────────────

  @override
  Future<Evaluation?> getLatestForStudent(String email) async {
    final db  = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT e.*, gc.name AS category_name
      FROM evaluations e
      JOIN group_categories gc ON gc.id = e.category_id
      JOIN groups g            ON g.category_id = e.category_id
      JOIN group_members gm    ON gm.group_id = g.id
      WHERE LOWER(gm.username) = ?
      ORDER BY e.created_at DESC
      LIMIT 1
    ''', [email.toLowerCase()]);
    if (rows.isEmpty) return null;
    return _rowToEval(rows.first);
  }

  @override
  Future<String?> getGroupNameForStudent(int evalId, String email) async {
    final db  = await _db.database;
    final rows = await db.rawQuery('''
      SELECT g.name
      FROM groups g
      JOIN group_members gm ON gm.group_id = g.id
      JOIN evaluations e    ON e.category_id = g.category_id
      WHERE e.id = ? AND LOWER(gm.username) = ?
      LIMIT 1
    ''', [evalId, email.toLowerCase()]);
    if (rows.isEmpty) return null;
    return rows.first['name'] as String;
  }

  @override
  Future<List<Peer>> getPeersForStudent(int evalId, String email) async {
    final db = await _db.database;
    // Find this student's group within the eval's category
    final groupRows = await db.rawQuery('''
      SELECT g.id
      FROM groups g
      JOIN group_members gm ON gm.group_id = g.id
      JOIN evaluations e    ON e.category_id = g.category_id
      WHERE e.id = ? AND LOWER(gm.username) = ?
      LIMIT 1
    ''', [evalId, email.toLowerCase()]);
    if (groupRows.isEmpty) return [];
    final groupId = groupRows.first['id'] as int;
    // All group members except self
    final memberRows = await db.query(
      'group_members',
      where: 'group_id = ? AND LOWER(username) != ?',
      whereArgs: [groupId, email.toLowerCase()],
    );
    return memberRows.map((m) {
      final name = m['name'] as String;
      return Peer(
        id:       (m['id'] as int).toString(),
        name:     name,
        initials: _buildInitials(name),
      );
    }).toList();
  }

  @override
  Future<List<Course>> getCoursesForStudent(String email) async {
    final db  = await _db.database;
    final rows = await db.rawQuery('''
      SELECT g.id, gc.name AS cat_name, g.name AS grp_name,
             COUNT(gm2.id) AS member_count
      FROM group_members gm
      JOIN groups g            ON g.id = gm.group_id
      JOIN group_categories gc ON gc.id = g.category_id
      JOIN group_members gm2   ON gm2.group_id = g.id
      WHERE LOWER(gm.username) = ?
      GROUP BY g.id
    ''', [email.toLowerCase()]);
    return rows.map((r) => Course(
      id:          (r['id'] as int).toString(),
      name:        r['cat_name'] as String,
      groupName:   r['grp_name'] as String,
      memberCount: r['member_count'] as int,
    )).toList();
  }

  // ── Responses ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveResponses({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
    required Map<String, int> scores,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final entry in scores.entries) {
        await txn.insert('evaluation_responses', {
          'eval_id':              evalId,
          'evaluator_id':         evaluatorStudentId,
          'evaluated_member_id':  evaluatedMemberId,
          'criterion_id':         entry.key,
          'score':                entry.value,
        });
      }
    });
  }

  @override
  Future<bool> hasEvaluated({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
  }) async {
    final db   = await _db.database;
    final rows = await db.query(
      'evaluation_responses',
      where: 'eval_id = ? AND evaluator_id = ? AND evaluated_member_id = ?',
      whereArgs: [evalId, evaluatorStudentId, evaluatedMemberId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<CriterionResult>> getMyResults(
      int evalId, String email) async {
    final db = await _db.database;
    // Find group_member ids for this student in this eval's category
    final memberRows = await db.rawQuery('''
      SELECT gm.id
      FROM group_members gm
      JOIN groups g         ON g.id = gm.group_id
      JOIN evaluations e    ON e.category_id = g.category_id
      WHERE e.id = ? AND LOWER(gm.username) = ?
    ''', [evalId, email.toLowerCase()]);
    if (memberRows.isEmpty) return [];
    final memberIds   = memberRows.map((r) => r['id'] as int).toList();
    final placeholders = List.filled(memberIds.length, '?').join(',');
    final rows = await db.rawQuery('''
      SELECT criterion_id, AVG(CAST(score AS REAL)) AS avg_score
      FROM evaluation_responses
      WHERE eval_id = ? AND evaluated_member_id IN ($placeholders) AND score >= 2
      GROUP BY criterion_id
    ''', [evalId, ...memberIds]);
    final avgMap = <String, double>{};
    for (final r in rows) {
      avgMap[r['criterion_id'] as String] = r['avg_score'] as double;
    }
    return EvalCriterion.defaults.map((c) {
      final val = avgMap[c.id] ?? 0.0;
      return CriterionResult(
        label: c.label,
        value: double.parse(val.toStringAsFixed(1)),
      );
    }).toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Evaluation _rowToEval(Map<String, Object?> row) {
    return Evaluation(
      id:           row['id']          as int,
      name:         row['name']        as String,
      categoryId:   row['category_id'] as int,
      categoryName: row['category_name'] as String,
      hours:        row['hours']       as int,
      visibility:   row['visibility']  as String,
      createdAt:    DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      closesAt:     DateTime.fromMillisecondsSinceEpoch(row['closes_at']  as int),
    );
  }
}
