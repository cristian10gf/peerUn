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

class _StudentIdentity {
  final String normalizedEmail;
  final int? numericId;
  final String rawUserId;

  const _StudentIdentity({
    required this.normalizedEmail,
    required this.numericId,
    required this.rawUserId,
  });
}

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

  Future<_StudentIdentity> _resolveStudentIdentity(String email) async {
    final normalized = email.toLowerCase();
    final users = await _db.robleRead(RobleTables.users);

    for (final user in users) {
      final userEmail = _asString(user['email']).toLowerCase();
      final username = _asString(user['username']).toLowerCase();
      if ((userEmail.isNotEmpty && userEmail == normalized) ||
          (username.isNotEmpty && username == normalized)) {
        final rawUserId = _asString(user['user_id']);
        final idSeed =
            user['id'] ??
            user['_id'] ??
            (rawUserId.isNotEmpty ? rawUserId : normalized);
        return _StudentIdentity(
          normalizedEmail: normalized,
          numericId: DatabaseService.stableNumericIdFromSeed(idSeed.toString()),
          rawUserId: rawUserId,
        );
      }
    }

    return _StudentIdentity(
      normalizedEmail: normalized,
      numericId: DatabaseService.stableNumericIdFromSeed(normalized),
      rawUserId: '',
    );
  }

  bool _matchesStudentMembership(
    Map<String, dynamic> row,
    _StudentIdentity identity,
  ) {
    return _isMembershipForStudent(
      row,
      identity.normalizedEmail,
      identity.numericId,
      studentRawUserId: identity.rawUserId,
    );
  }

  String _memberDisplayName(Map<String, dynamic> row) {
    final directName = _asString(row['name']).trim();
    if (directName.isNotEmpty && !_looksLikeCode(directName)) {
      return directName;
    }

    final email = _asString(row['email']).trim();
    if (email.isNotEmpty) {
      final at = email.indexOf('@');
      return at > 0 ? email.substring(0, at) : email;
    }

    final username = _asString(row['username']).trim();
    if (username.isNotEmpty) return username;

    return 'Integrante ${_rowId(row)}';
  }

  bool _isMembershipForStudent(
    Map<String, dynamic> row,
    String normalizedEmail,
    int? studentUserId, {
    String studentRawUserId = '',
  }) {
    final rowEmail = _asString(row['email']).toLowerCase();
    final rowUsername = _asString(row['username']).toLowerCase();
    final rowRawUserId = _asString(row['user_id']);
    final rowUserId = _asInt(row['user_id'], fallback: -1);

    if (rowEmail.isNotEmpty && rowEmail == normalizedEmail) return true;
    if (rowUsername.isNotEmpty && rowUsername == normalizedEmail) return true;
    if (studentRawUserId.isNotEmpty && rowRawUserId == studentRawUserId) {
      return true;
    }
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

  /// Returns all groups whose category_id UUID hashes to [categoryDomainId].
  /// Evaluations store category_id as stableNumericIdFromSeed(categoryUUID),
  /// so we reverse-match by computing the same hash for each group's ref.
  List<Map<String, dynamic>> _groupsForCategoryDomain(
    List<Map<String, dynamic>> groups,
    int categoryDomainId,
  ) {
    return groups.where((g) {
      final ref = _asString(g['category_id']);
      return ref.isNotEmpty &&
          DatabaseService.stableNumericIdFromSeed(ref) == categoryDomainId;
    }).toList();
  }

  /// Returns all user_group rows that belong to [group], matched by the group's
  /// UUID ref (group['group_id']).  Using _rowId() here would fail because
  /// user_group.group_id stores the UUID, not an integer.
  List<Map<String, dynamic>> _membersForGroup(
    List<Map<String, dynamic>> allMembers,
    Map<String, dynamic> group,
  ) {
    final groupRef = _asString(group['group_id']);
    if (groupRef.isEmpty) return const [];
    return allMembers
        .where((m) => _asString(m['group_id']) == groupRef)
        .toList();
  }

  bool _isOwnedByTeacher(Map<String, dynamic> row, int teacherId) {
    final legacyTeacher = _asInt(row['teacher_id'], fallback: -1);
    final schemaTeacher = _asInt(row['created_by'], fallback: -1);
    return legacyTeacher == teacherId || schemaTeacher == teacherId;
  }

  String _evalName(Map<String, dynamic> row, {String fallback = ''}) {
    final legacy = _asString(row['name']);
    if (legacy.isNotEmpty) return legacy;
    final schema = _asString(row['title']);
    if (schema.isNotEmpty) return schema;
    return fallback;
  }

  DateTime _evalCreatedAt(Map<String, dynamic> row, {DateTime? fallback}) {
    return _asDate(row['created_at'] ?? row['start_date'] ?? fallback);
  }

  DateTime _evalClosesAt(Map<String, dynamic> row, {DateTime? fallback}) {
    return _asDate(row['closes_at'] ?? row['end_date'] ?? fallback);
  }

  int _evalHours(
    Map<String, dynamic> row, {
    required int fallback,
    DateTime? createdAt,
    DateTime? closesAt,
  }) {
    final explicit = _asInt(row['hours'], fallback: -1);
    if (explicit > 0) return explicit;

    final from = createdAt ?? _evalCreatedAt(row, fallback: DateTime.now());
    final to = closesAt ?? _evalClosesAt(row, fallback: from);
    final computed = to.difference(from).inHours;
    if (computed > 0) return computed;
    return fallback;
  }

  String _evalVisibility(
    Map<String, dynamic> row, {
    String fallback = 'private',
  }) {
    final direct = _asString(row['visibility']).toLowerCase();
    if (direct == 'public' || direct == 'private') return direct;

    final fromDescription = _asString(row['description']).toLowerCase();
    if (fromDescription == 'public' || fromDescription == 'private') {
      return fromDescription;
    }
    return fallback;
  }

  bool _looksLikeSchemaMismatch(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('column') ||
        msg.contains('schema') ||
        msg.contains('does not exist') ||
        msg.contains('invalid');
  }

  Future<void> _updateEvaluationName(
    String rowKey,
    String newName,
    Map<String, dynamic> currentRow,
  ) async {
    final prefersSchemaField =
        currentRow.containsKey('title') && !currentRow.containsKey('name');
    final primaryField = prefersSchemaField ? 'title' : 'name';
    final fallbackField = prefersSchemaField ? 'name' : 'title';

    try {
      await _db.robleUpdate(RobleTables.evaluation, rowKey, {
        primaryField: newName,
      });
    } catch (error) {
      if (!_looksLikeSchemaMismatch(error)) rethrow;
      await _db.robleUpdate(RobleTables.evaluation, rowKey, {
        fallbackField: newName,
      });
    }
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
    final existing = await _db.robleRead(RobleTables.evaluation);
    final duplicate = existing.any(
      (row) =>
          _isOwnedByTeacher(row, teacherId) &&
          _evalName(row).toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw Exception('Ya existe una evaluación con ese nombre');
    }

    final now = DateTime.now();
    final closesAt = now.add(Duration(hours: hours));

    Map<String, dynamic> row;
    try {
      row = await _db.robleCreate(RobleTables.evaluation, {
        'title': name,
        'category_id': categoryId,
        'created_by': teacherId,
        'description': visibility,
        'start_date': now.toIso8601String(),
        'end_date': closesAt.toIso8601String(),
      });
    } catch (error) {
      if (!_looksLikeSchemaMismatch(error)) rethrow;
      row = await _db.robleCreate(RobleTables.evaluation, {
        'name': name,
        'category_id': categoryId,
        'hours': hours,
        'visibility': visibility,
        'created_at': now.millisecondsSinceEpoch,
        'closes_at': closesAt.millisecondsSinceEpoch,
        'teacher_id': teacherId,
      });
    }

    final catRows = await _db.robleRead(RobleTables.category);
    final category = _findById(catRows, categoryId);
    final catName = category == null ? '' : _asString(category['name']);

    final createdAt = _evalCreatedAt(
      row,
      fallback: DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch),
    );
    final closeAt = _evalClosesAt(
      row,
      fallback: DateTime.fromMillisecondsSinceEpoch(
        closesAt.millisecondsSinceEpoch,
      ),
    );

    return Evaluation(
      id: _rowId(row),
      name: _evalName(row, fallback: name),
      categoryId: _asInt(row['category_id'], fallback: categoryId),
      categoryName: catName,
      hours: _evalHours(
        row,
        fallback: hours,
        createdAt: createdAt,
        closesAt: closeAt,
      ),
      visibility: _evalVisibility(row, fallback: visibility),
      createdAt: createdAt,
      closesAt: closeAt,
    );
  }

  // ── All evaluations ────────────────────────────────────────────────────────

  @override
  Future<List<Evaluation>> getAll(int teacherId) async {
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final visibleRows = evalRows
        .where((row) => _isOwnedByTeacher(row, teacherId))
        .toList(growable: false);
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

    final list = visibleRows.map((row) {
      final catId = _asInt(row['category_id']);
      final cat = catById[catId];
      final courseName = cat == null
          ? ''
          : (courseById[_asInt(cat['course_id'])] ?? '');
      final createdAt = _evalCreatedAt(row, fallback: DateTime.now());
      final closeAt = _evalClosesAt(row, fallback: createdAt);

      return Evaluation(
        id: _rowId(row),
        name: _evalName(row),
        categoryId: catId,
        categoryName: cat == null ? '' : _asString(cat['name']),
        courseName: courseName,
        hours: _evalHours(
          row,
          fallback: 24,
          createdAt: createdAt,
          closesAt: closeAt,
        ),
        visibility: _evalVisibility(row),
        createdAt: createdAt,
        closesAt: closeAt,
      );
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> rename(int evalId, String newName, int teacherId) async {
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final teacherRows = evalRows
        .where((row) => _isOwnedByTeacher(row, teacherId))
        .toList(growable: false);

    for (final row in teacherRows) {
      if (_rowId(row) != evalId &&
          _evalName(row).toLowerCase() == newName.toLowerCase()) {
        throw Exception('Ya existe una evaluación con ese nombre');
      }
    }

    final target = _findById(teacherRows, evalId);
    final key = target?['_id']?.toString();
    if (key == null || key.isEmpty) {
      throw Exception('No se encontró la evaluación');
    }

    await _updateEvaluationName(key, newName, target!);
  }

  @override
  Future<void> delete(int evalId) async {
    // Delete the evaluation record first.
    // If this throws, criteria are still intact — no data is orphaned.
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final target = _findById(evalRows, evalId);
    final evalKey = target?['_id']?.toString();
    if (evalKey != null && evalKey.isNotEmpty) {
      await _db.robleDelete(RobleTables.evaluation, evalKey);
    }

    // Evaluation confirmed deleted; clean up criteria best-effort.
    // Orphaned criterium rows are harmless (no parent evaluation to join against).
    final criteriumRows = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {'eval_id': evalId},
    );
    for (final row in criteriumRows) {
      final key = row['_id']?.toString();
      if (key != null && key.isNotEmpty) {
        try {
          await _db.robleDelete(RobleTables.evaluationCriterium, key);
        } catch (_) {
          // Best-effort: orphaned criterium rows without a parent evaluation
          // are invisible to all queries that filter by eval_id.
        }
      }
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
        GroupResultsInputGroup(id: groupId, name: _asString(group['name'])),
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
    final identity = await _resolveStudentIdentity(email);
    final members = await _db.robleRead(RobleTables.userGroup);
    final groups = await _db.robleRead(RobleTables.groups);
    final categories = await _db.robleRead(RobleTables.category);
    final courses = await _db.robleRead(RobleTables.course);
    final evals = await _db.robleRead(RobleTables.evaluation);

    // group_id and category_id are stored as UUID strings — use string refs.
    final myGroupRefs = members
        .where((m) => _matchesStudentMembership(m, identity))
        .map((m) => _asString(m['group_id']))
        .where((ref) => ref.isNotEmpty)
        .toSet();

    if (myGroupRefs.isEmpty) return [];

    // Build group ref → group row lookup.
    final groupByRef = <String, Map<String, dynamic>>{};
    for (final g in groups) {
      final ref = _asString(g['group_id']);
      if (ref.isNotEmpty) groupByRef[ref] = g;
    }

    // Evaluations store category_id as stableNumericIdFromSeed(categoryRef).
    final myCategoryIds = myGroupRefs
        .map((ref) => groupByRef[ref])
        .where((g) => g != null)
        .map((g) => DatabaseService.stableNumericIdFromSeed(
              _asString(g!['category_id']),
            ))
        .toSet();

    // Key by domain integer (stableNumericIdFromSeed of the UUID ref) to match
    // the value stored in evaluation.category_id / category.course_id.
    final catById = <int, Map<String, dynamic>>{};
    for (final c in categories) {
      final ref = _asString(c['category_id']);
      if (ref.isNotEmpty) {
        catById[DatabaseService.stableNumericIdFromSeed(ref)] = c;
      }
    }

    final courseById = <int, String>{};
    for (final c in courses) {
      final ref = _asString(c['course_id']);
      if (ref.isNotEmpty) {
        courseById[DatabaseService.stableNumericIdFromSeed(ref)] =
            _asString(c['name']);
      }
    }

    final list = evals
        .where((e) => myCategoryIds.contains(_asInt(e['category_id'])))
        .map((row) {
          final catId = _asInt(row['category_id']);
          final cat = catById[catId];
          final courseName = cat == null
              ? ''
              : (courseById[DatabaseService.stableNumericIdFromSeed(
                    _asString(cat['course_id']),
                  )] ??
                  '');

          final createdAt = _evalCreatedAt(row, fallback: DateTime.now());
          final closesAt = _evalClosesAt(row, fallback: createdAt);

          return Evaluation(
            id: _rowId(row),
            name: _evalName(row),
            categoryId: catId,
            categoryName: cat == null ? '' : _asString(cat['name']),
            courseName: courseName,
            hours: _evalHours(
              row,
              fallback: 24,
              createdAt: createdAt,
              closesAt: closesAt,
            ),
            visibility: _evalVisibility(row),
            createdAt: createdAt,
            closesAt: closesAt,
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
    final identity = await _resolveStudentIdentity(email);

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return null;

    final categoryId = _asInt(eval['category_id']);
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);

    for (final g in _groupsForCategoryDomain(allGroups, categoryId)) {
      final members = _membersForGroup(allMembers, g);
      if (members.any((m) => _matchesStudentMembership(m, identity))) {
        return _asString(g['name']);
      }
    }
    return null;
  }

  @override
  Future<List<Peer>> getPeersForStudent(int evalId, String email) async {
    final identity = await _resolveStudentIdentity(email);

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);

    List<Map<String, dynamic>>? myGroupMembers;
    for (final g in _groupsForCategoryDomain(allGroups, categoryId)) {
      final members = _membersForGroup(allMembers, g);
      if (members.any((m) => _matchesStudentMembership(m, identity))) {
        myGroupMembers = members;
        break;
      }
    }

    if (myGroupMembers == null) return [];

    return myGroupMembers
        .where((m) => !_matchesStudentMembership(m, identity))
        .map((m) {
          final name = _memberDisplayName(m);
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
    final identity = await _resolveStudentIdentity(email);
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
        .where((m) => _matchesStudentMembership(m, identity))
        .toList();

    final result = <Course>[];
    for (final m in myMemberships) {
      final groupId = _asInt(m['group_id']);
      final group = groupsById[groupId];
      if (group == null) continue;

      final category = categoryById[_asInt(group['category_id'])];
      final memberCount = members
          .where((x) => _asInt(x['group_id']) == groupId)
          .length;

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
    final identity = await _resolveStudentIdentity(email);
    final normalized = identity.normalizedEmail;
    final studentUserId = identity.numericId;
    final now = DateTime.now();

    final users = await _db.robleRead(RobleTables.users);
    final userCourses = await _db.robleRead(RobleTables.userCourse);
    final courses = await _db.robleRead(RobleTables.course);
    final categories = await _db.robleRead(RobleTables.category);
    final groups = await _db.robleRead(RobleTables.groups);
    final members = await _db.robleRead(RobleTables.userGroup);
    final evaluations = await _db.robleRead(RobleTables.evaluation);
    final responses = await _db.robleRead(RobleTables.evaluationCriterium);

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
    }

    // Use string UUID refs as map keys — FK fields like group_id / category_id
    // are stored as UUID strings, not integers, so _asInt() would return 0 for
    // all of them and collapse every lookup to the same bucket.

    final enrolledCourseRefs = <String>{};
    for (final row in userCourses) {
      final role = _asString(row['role']).toLowerCase();
      if (role.isNotEmpty && role != 'student') continue;
      if (_isMembershipForStudent(
        row,
        normalized,
        studentUserId,
        studentRawUserId: identity.rawUserId,
      )) {
        final courseRef = _asString(row['course_id']);
        if (courseRef.isNotEmpty) enrolledCourseRefs.add(courseRef);
      }
    }

    // group['category_id'] is the category UUID ref.
    final groupsByCategoryRef = <String, List<Map<String, dynamic>>>{};
    for (final group in groups) {
      final categoryRef = _asString(group['category_id']);
      if (categoryRef.isNotEmpty) {
        groupsByCategoryRef.putIfAbsent(categoryRef, () => []).add(group);
      }
    }

    // member['group_id'] is the group UUID ref.
    final membersByGroupRef = <String, List<Map<String, dynamic>>>{};
    for (final member in members) {
      final groupRef = _asString(member['group_id']);
      if (groupRef.isNotEmpty) {
        membersByGroupRef.putIfAbsent(groupRef, () => []).add(member);
      }
    }

    // category['course_id'] is the course UUID ref.
    final categoriesByCourseRef = <String, List<Map<String, dynamic>>>{};
    for (final category in categories) {
      final courseRef = _asString(category['course_id']);
      if (courseRef.isNotEmpty) {
        categoriesByCourseRef.putIfAbsent(courseRef, () => []).add(category);
      }
    }

    // Keyed by category UUID ref.
    final myGroupByCategoryRef = <String, Map<String, dynamic>>{};
    final myMemberByCategoryRef = <String, Map<String, dynamic>>{};

    for (final category in categories) {
      final categoryRef = _asString(category['category_id']);
      if (categoryRef.isEmpty) continue;
      final categoryGroups = groupsByCategoryRef[categoryRef] ?? const [];
      for (final group in categoryGroups) {
        final groupRef = _asString(group['group_id']);
        final groupMembers = membersByGroupRef[groupRef] ?? const [];

        Map<String, dynamic>? myMember;
        for (final member in groupMembers) {
          if (_isMembershipForStudent(
            member,
            normalized,
            studentUserId,
            studentRawUserId: identity.rawUserId,
          )) {
            myMember = member;
            break;
          }
        }

        if (myMember != null) {
          myGroupByCategoryRef[categoryRef] = group;
          myMemberByCategoryRef[categoryRef] = myMember;
          final courseRef = _asString(category['course_id']);
          if (courseRef.isNotEmpty) enrolledCourseRefs.add(courseRef);
          break;
        }
      }
    }

    // Evaluations store category_id as the domain integer produced by
    // stableNumericIdFromSeed(categoryRef), so key this map the same way.
    final activeEvalByCategory = <int, Map<String, dynamic>>{};
    for (final row in evaluations) {
      final createdAt = _evalCreatedAt(row, fallback: now);
      final closesAt = _evalClosesAt(row, fallback: createdAt);
      if (closesAt.isBefore(now)) continue;
      final categoryId = _asInt(row['category_id']);
      final current = activeEvalByCategory[categoryId];
      if (current == null ||
          createdAt.isAfter(_evalCreatedAt(current, fallback: now))) {
        activeEvalByCategory[categoryId] = row;
      }
    }

    final responseRowsByEvalAndEvaluator = <String, Set<int>>{};
    for (final row in responses) {
      final evalId = _asInt(row['eval_id'] ?? row['evaluation_id']);
      final evaluatorId = _asInt(row['evaluator_id']);
      final evaluatedMemberId = _asInt(
        row['evaluated_member_id'],
        fallback: -1,
      );
      if (evaluatedMemberId <= 0) continue;

      final key = '$evalId:$evaluatorId';
      responseRowsByEvalAndEvaluator
          .putIfAbsent(key, () => <int>{})
          .add(evaluatedMemberId);
    }

    // course['course_id'] is the course UUID ref.
    final coursesByRef = <String, Map<String, dynamic>>{};
    for (final course in courses) {
      final courseRef = _asString(course['course_id']);
      if (courseRef.isNotEmpty) coursesByRef[courseRef] = course;
    }

    final result = <StudentHomeCourse>[];
    for (final courseRef in enrolledCourseRefs) {
      final course = coursesByRef[courseRef];
      final categoryRows = categoriesByCourseRef[courseRef] ?? const [];

      final homeCategories = <StudentHomeCategory>[];
      for (final category in categoryRows) {
        final categoryRef = _asString(category['category_id']);
        final group = myGroupByCategoryRef[categoryRef];
        if (group == null) continue;

        final groupRef = _asString(group['group_id']);
        final groupMembers = membersByGroupRef[groupRef] ?? const [];

        // Build peer list — exclude the current student (Bug fix: student was
        // previously included in their own group member display).
        final mappedMembers = <GroupMember>[];
        for (final member in groupMembers) {
          if (_isMembershipForStudent(
            member,
            normalized,
            studentUserId,
            studentRawUserId: identity.rawUserId,
          )) {
            continue; // skip self
          }

          final memberRowId = _rowId(member);
          final rawMemberUserId = _asString(member['user_id']);
          final linkedUser =
              usersByRawId[rawMemberUserId] ??
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
            memberName = at > 0
                ? memberIdentity.substring(0, at)
                : memberIdentity;
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

        // categoryRef → domain integer: evaluations store category_id using
        // stableNumericIdFromSeed(categoryRef), so use the same conversion.
        final categoryDomainId =
            DatabaseService.stableNumericIdFromSeed(categoryRef);
        final activeEval = activeEvalByCategory[categoryDomainId];
        final activeEvalId = activeEval == null ? 0 : _rowId(activeEval);
        final activeEvalName = activeEval == null ? '' : _evalName(activeEval);

        // Peer IDs for completion tracking (exclude student, keep integer IDs).
        final myMemberRow = myMemberByCategoryRef[categoryRef];
        final myMemberId = myMemberRow == null ? -1 : _rowId(myMemberRow);
        final peerMemberIds = groupMembers
            .map(_rowId)
            .where((id) => id != myMemberId)
            .toSet();

        var completedPeerCount = 0;
        if (activeEval != null &&
            studentUserId != null &&
            peerMemberIds.isNotEmpty) {
          final key = '$activeEvalId:$studentUserId';
          final evaluatedMemberIds =
              responseRowsByEvalAndEvaluator[key] ?? const <int>{};
          completedPeerCount = evaluatedMemberIds
              .where(peerMemberIds.contains)
              .length;
        }

        final categoryDomainIdForModel =
            DatabaseService.stableNumericIdFromSeed(categoryRef);
        final groupDomainId =
            DatabaseService.stableNumericIdFromSeed(_asString(group['group_id']));

        homeCategories.add(
          StudentHomeCategory(
            id: categoryDomainIdForModel,
            name: _asString(category['name']),
            group: StudentHomeGroup(
              id: groupDomainId,
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

      homeCategories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      result.add(
        StudentHomeCourse(
          id: DatabaseService.stableNumericIdFromSeed(courseRef),
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
    // Load existing responses for this evaluator→evaluated pair once
    // to determine whether to create or update.
    final existing = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {
        'eval_id': evalId,
        'evaluator_id': evaluatorStudentId,
        'evaluated_member_id': evaluatedMemberId,
      },
    );
    final existingByCriterion = <String, String>{}; // criterionId → _id
    for (final row in existing) {
      final cid = _asString(row['criterion_id']);
      final key = _asString(row['_id']);
      if (cid.isNotEmpty && key.isNotEmpty) {
        existingByCriterion[cid] = key;
      }
    }

    for (final entry in scores.entries) {
      final criterionId = entry.key;
      final score = entry.value;
      final existingKey = existingByCriterion[criterionId];
      if (existingKey != null) {
        // Update instead of creating a duplicate.
        await _db.robleUpdate(
          RobleTables.evaluationCriterium,
          existingKey,
          {'score': score},
        );
      } else {
        await _db.robleCreate(RobleTables.evaluationCriterium, {
          'eval_id': evalId,
          'evaluator_id': evaluatorStudentId,
          'evaluated_member_id': evaluatedMemberId,
          'criterion_id': criterionId,
          'score': score,
        });
      }
    }
  }

  @override
  Future<bool> hasEvaluated({
    required int evalId,
    required int evaluatorStudentId,
    required int evaluatedMemberId,
  }) async {
    final rows = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {
        'eval_id': evalId,
        'evaluator_id': evaluatorStudentId,
        'evaluated_member_id': evaluatedMemberId,
      },
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<CriterionResult>> getMyResults(int evalId, String email) async {
    final identity = await _resolveStudentIdentity(email);

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);

    final myMemberIds = <int>{};
    for (final g in _groupsForCategoryDomain(allGroups, categoryId)) {
      for (final m in _membersForGroup(allMembers, g)) {
        if (_matchesStudentMembership(m, identity)) {
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

      final cid = _asString(r['criterion_id'] ?? r['criterium_id']);
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
    final identity = await _resolveStudentIdentity(email);

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findById(evalRows, evalId);
    if (eval == null) return false;

    final categoryId = _asInt(eval['category_id']);
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);

    List<Map<String, dynamic>>? myGroupMembers;
    for (final g in _groupsForCategoryDomain(allGroups, categoryId)) {
      final members = _membersForGroup(allMembers, g);
      if (members.any((m) => _matchesStudentMembership(m, identity))) {
        myGroupMembers = members;
        break;
      }
    }

    if (myGroupMembers == null) return false;

    final peerIds = myGroupMembers
        .where((m) => !_matchesStudentMembership(m, identity))
        .map(_rowId)
        .toSet();

    if (peerIds.isEmpty) return false;

    final responses = await _db.robleRead(
      RobleTables.evaluationCriterium,
      filters: {'eval_id': evalId, 'evaluator_id': studentId},
    );

    final doneIds = <int>{};
    for (final r in responses) {
      final target = _asInt(r['evaluated_member_id']);
      if (peerIds.contains(target)) doneIds.add(target);
    }

    return doneIds.length >= peerIds.length;
  }
}
