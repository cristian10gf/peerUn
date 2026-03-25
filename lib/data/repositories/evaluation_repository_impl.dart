import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/data/utils/string_utils.dart';
import 'package:example/data/utils/value_parsers.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/services/group_results_domain_service.dart';

class EvaluationRepositoryImpl implements IEvaluationRepository {
  final DatabaseService _db;
  final GroupResultsDomainService _groupResultsDomainService;

  EvaluationRepositoryImpl(
    this._db, {
    GroupResultsDomainService? groupResultsDomainService,
  }) : _groupResultsDomainService =
           groupResultsDomainService ?? const GroupResultsDomainService();

  int _asInt(dynamic value, {int fallback = 0}) =>
      asInt(value, fallback: fallback);

  String _asString(dynamic value) => asString(value);

  int _rowId(Map<String, dynamic> row) => rowIdFromMap(row);

  DateTime _asDate(dynamic value) => asDate(value);

  Map<String, dynamic>? _findById(List<Map<String, dynamic>> rows, int id) {
    for (final row in rows) {
      if (_rowId(row) == id) return row;
    }
    return null;
  }

  bool _isMembershipForStudent(
    Map<String, dynamic> row,
    String normalizedEmail,
    int? studentUserId,
  ) {
    final rowEmail = _asString(row['email']).toLowerCase();
    final rowUsername = _asString(row['username']).toLowerCase();
    final rowUserId = _asInt(row['user_id'], fallback: -1);

    if (rowEmail.isNotEmpty && rowEmail == normalizedEmail) return true;
    if (rowUsername.isNotEmpty && rowUsername == normalizedEmail) return true;
    if (studentUserId != null && rowUserId == studentUserId) return true;
    return false;
  }

  bool _looksLikeCode(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (v.contains('@')) return true;
    final hasSpace = v.contains(' ');
    final hasLetters = RegExp('[A-Za-z]').hasMatch(v);
    final hasDigits = RegExp(r'\d').hasMatch(v);
    return !hasSpace && hasLetters && hasDigits;
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

    final inputGroups = <GroupResultsInputGroup>[];
    final inputMembers = <GroupResultsInputMember>[];

    for (final group in groups) {
      final groupId = _rowId(group);
      inputGroups.add(
        GroupResultsInputGroup(
          id: groupId,
          name: _asString(group['name']),
        ),
      );

      final memberRows = await _db.robleRead(
        RobleTables.userGroup,
        filters: {'group_id': groupId},
      );

      for (final member in memberRows) {
        inputMembers.add(
          GroupResultsInputMember(
            groupId: groupId,
            memberId: _rowId(member),
            name: _asString(member['name']),
          ),
        );
      }
    }

    final inputResponses = responses
        .map(
          (response) => GroupResultsInputResponse(
            evaluatedMemberId: _asInt(response['evaluated_member_id']),
            criterionId: _asString(response['criterion_id']),
            score: _asInt(response['score']),
          ),
        )
        .toList(growable: false);

    return _groupResultsDomainService.buildGroupResults(
      groups: inputGroups,
      members: inputMembers,
      responses: inputResponses,
    );
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

  @override
  Future<List<StudentHomeCourse>> getStudentHomeCourses(String email) async {
    final normalized = email.toLowerCase();
    final now = DateTime.now();

    final users = await _db.robleRead(RobleTables.users);
    final userCourses = await _db.robleRead(RobleTables.userCourse);
    final courses = await _db.robleRead(RobleTables.course);
    final categories = await _db.robleRead(RobleTables.category);
    final groups = await _db.robleRead(RobleTables.groups);
    final members = await _db.robleRead(RobleTables.userGroup);
    final evaluations = await _db.robleRead(RobleTables.evaluation);
    final responses = await _db.robleRead(RobleTables.evaluationCriterium);

    int? studentUserId;
    final usersById = <int, Map<String, dynamic>>{};
    final usersByRawId = <String, Map<String, dynamic>>{};
    final usersByEmail = <String, Map<String, dynamic>>{};
    for (final user in users) {
      usersById[_asInt(user['id'] ?? user['_id'])] = user;
      final rawUserId = _asString(user['user_id']);
      if (rawUserId.isNotEmpty) {
        usersByRawId[rawUserId] = user;
      }
      final userEmail = _asString(user['email']).toLowerCase();
      if (userEmail.isNotEmpty) {
        usersByEmail[userEmail] = user;
      }
      if (userEmail == normalized) {
        studentUserId = _rowId(user);
      }
    }

    final enrolledCourseIds = <int>{};
    for (final row in userCourses) {
      final role = _asString(row['role']).toLowerCase();
      if (role.isNotEmpty && role != 'student') continue;
      if (_isMembershipForStudent(row, normalized, studentUserId)) {
        enrolledCourseIds.add(_asInt(row['course_id']));
      }
    }

    final groupsByCategory = <int, List<Map<String, dynamic>>>{};
    for (final group in groups) {
      final categoryId = _asInt(group['category_id']);
      groupsByCategory.putIfAbsent(categoryId, () => []).add(group);
    }

    final membersByGroup = <int, List<Map<String, dynamic>>>{};
    for (final member in members) {
      final groupId = _asInt(member['group_id']);
      membersByGroup.putIfAbsent(groupId, () => []).add(member);
    }

    final categoryById = <int, Map<String, dynamic>>{};
    final categoriesByCourse = <int, List<Map<String, dynamic>>>{};
    for (final category in categories) {
      final categoryId = _rowId(category);
      final courseId = _asInt(category['course_id']);
      categoryById[categoryId] = category;
      categoriesByCourse.putIfAbsent(courseId, () => []).add(category);
    }

    final myGroupByCategory = <int, Map<String, dynamic>>{};
    final myMemberIdByCategory = <int, int>{};

    for (final category in categories) {
      final categoryId = _rowId(category);
      final categoryGroups = groupsByCategory[categoryId] ?? const [];
      for (final group in categoryGroups) {
        final groupId = _rowId(group);
        final groupMembers = membersByGroup[groupId] ?? const [];

        Map<String, dynamic>? myMember;
        for (final member in groupMembers) {
          if (_isMembershipForStudent(member, normalized, studentUserId)) {
            myMember = member;
            break;
          }
        }

        if (myMember != null) {
          myGroupByCategory[categoryId] = group;
          myMemberIdByCategory[categoryId] = _rowId(myMember);
          enrolledCourseIds.add(_asInt(category['course_id']));
          break;
        }
      }
    }

    final activeEvalByCategory = <int, Map<String, dynamic>>{};
    for (final row in evaluations) {
      final closesAt = _asDate(row['closes_at']);
      if (closesAt.isBefore(now)) continue;
      final categoryId = _asInt(row['category_id']);
      final current = activeEvalByCategory[categoryId];
      if (current == null || _asDate(row['created_at']).isAfter(_asDate(current['created_at']))) {
        activeEvalByCategory[categoryId] = row;
      }
    }

    final responseRowsByEvalAndEvaluator = <String, Set<int>>{};
    for (final row in responses) {
      final evalId = _asInt(row['eval_id']);
      final evaluatorId = _asInt(row['evaluator_id']);
      final evaluatedMemberId = _asInt(row['evaluated_member_id'], fallback: -1);
      if (evaluatedMemberId <= 0) continue;

      final key = '$evalId:$evaluatorId';
      responseRowsByEvalAndEvaluator.putIfAbsent(key, () => <int>{}).add(evaluatedMemberId);
    }

    final coursesById = <int, Map<String, dynamic>>{};
    for (final course in courses) {
      coursesById[_rowId(course)] = course;
    }

    final result = <StudentHomeCourse>[];
    for (final courseId in enrolledCourseIds) {
      final course = coursesById[courseId];
      final categoryRows = categoriesByCourse[courseId] ?? const [];

      final homeCategories = <StudentHomeCategory>[];
      for (final category in categoryRows) {
        final categoryId = _rowId(category);
        final group = myGroupByCategory[categoryId];
        if (group == null) continue;

        final groupId = _rowId(group);
        final groupMembers = membersByGroup[groupId] ?? const [];
        final mappedMembers = <GroupMember>[];
        for (final member in groupMembers) {
          final memberRowId = _rowId(member);
          final rawMemberUserId = _asString(member['user_id']);
          final linkedUser = usersByRawId[rawMemberUserId] ??
              usersById[_asInt(member['user_id'], fallback: -1)] ??
              usersByEmail[_asString(member['email']).toLowerCase()] ??
              usersByEmail[_asString(member['username']).toLowerCase()];

          var memberName = _asString(linkedUser?['name']);
          final memberNameFromMembership = _asString(member['name']);
          if (memberName.isEmpty || _looksLikeCode(memberName)) {
            memberName = memberNameFromMembership;
          }

          var memberIdentity = _asString(member['username']);
          if (memberIdentity.isEmpty) {
            memberIdentity = _asString(member['email']);
          }
          if (memberIdentity.isEmpty && linkedUser != null) {
            memberIdentity = _asString(linkedUser['email']);
          }

          if (memberName.isEmpty && memberIdentity.isNotEmpty) {
            final at = memberIdentity.indexOf('@');
            memberName = at > 0 ? memberIdentity.substring(0, at) : memberIdentity;
          }
          if (memberName.isEmpty) {
            memberName = 'Integrante $memberRowId';
          }

          mappedMembers.add(
            GroupMember(
              id: memberRowId,
              name: memberName,
              username: memberIdentity,
            ),
          );
        }

        final activeEval = activeEvalByCategory[categoryId];
        final activeEvalId = activeEval == null ? 0 : _rowId(activeEval);
        final activeEvalName = activeEval == null ? '' : _asString(activeEval['name']);

        final myMemberId = myMemberIdByCategory[categoryId];
        final peerMemberIds = groupMembers
            .map(_rowId)
            .where((memberId) => memberId != myMemberId)
            .toSet();

        var completedPeerCount = 0;
        if (activeEval != null && studentUserId != null && peerMemberIds.isNotEmpty) {
          final key = '$activeEvalId:$studentUserId';
          final evaluatedMemberIds = responseRowsByEvalAndEvaluator[key] ?? const <int>{};
          completedPeerCount = evaluatedMemberIds.where(peerMemberIds.contains).length;
        }

        homeCategories.add(
          StudentHomeCategory(
            id: categoryId,
            name: _asString(category['name']),
            group: StudentHomeGroup(
              id: groupId,
              name: _asString(group['name']),
              members: mappedMembers,
            ),
            activeEvaluationId: activeEvalId,
            activeEvaluationName: activeEvalName,
            completedPeerCount: completedPeerCount,
            totalPeerCount: peerMemberIds.length,
          ),
        );
      }

      homeCategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      result.add(
        StudentHomeCourse(
          id: courseId,
          name: course == null ? '' : _asString(course['name']),
          hasGroupAssignment: homeCategories.isNotEmpty,
          categories: homeCategories,
        ),
      );
    }

    result.sort((a, b) {
      if (a.hasGroupAssignment != b.hasGroupAssignment) {
        return a.hasGroupAssignment ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
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
