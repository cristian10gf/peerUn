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

  /// Stable domain integer ID for an evaluation row, derived from the UUID PK.
  /// Roble stores the evaluation PK in `evaluation_id` (varchar), not in `id`
  /// (integer), so _rowId returns 0 for all evaluation rows.
  int _evalDomainId(Map<String, dynamic> row) {
    final evalRef = _asString(row['evaluation_id']);
    if (evalRef.isNotEmpty) {
      return DatabaseService.stableNumericIdFromSeed(evalRef);
    }
    return _rowId(row);
  }

  /// Finds an evaluation row by its stable domain ID (stableNumericIdFromSeed
  /// of the evaluation_id UUID).  _findById is unreliable for evaluations
  /// because _rowId returns 0 for UUID-keyed rows.
  Map<String, dynamic>? _findEvalById(
      List<Map<String, dynamic>> rows, int id) {
    for (final row in rows) {
      if (_evalDomainId(row) == id) return row;
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

  /// Stable integer ID for a user_group row, derived from the user_id UUID.
  /// user_group rows do not carry a meaningful integer PK — Roble stores the
  /// PK in `_id` (a 12-char string), so `_rowId` returns 0 for all of them.
  /// Using stableNumericIdFromSeed(user_id) gives a unique, reproducible int
  /// that is consistent with group_repository_impl and the scores we persist.
  int _memberDomainId(Map<String, dynamic> memberRow) {
    final userRef = _asString(memberRow['user_id']);
    if (userRef.isNotEmpty) {
      return DatabaseService.stableNumericIdFromSeed(userRef);
    }
    return _rowId(memberRow);
  }

  /// Resolves a display name for a user_group [memberRow] using a pre-built
  /// [usersByRef] map (user_id / email → user row from the users table).
  String _memberNameFromUsers(
    Map<String, dynamic> memberRow,
    Map<String, Map<String, dynamic>> usersByRef,
  ) {
    final userRef = _asString(memberRow['user_id']);
    final user = usersByRef[userRef];

    var name = _asString(user?['name']).trim();
    if (name.isNotEmpty && !_looksLikeCode(name)) return name;

    var emailOrUser = _asString(user?['email']).trim();
    if (emailOrUser.isEmpty) emailOrUser = _asString(memberRow['email']).trim();
    if (emailOrUser.isNotEmpty) {
      final at = emailOrUser.indexOf('@');
      return at > 0 ? emailOrUser.substring(0, at) : emailOrUser;
    }

    // Fallback to the generic helper (reads name/email/username directly)
    return _memberDisplayName(memberRow);
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

  /// Ensures `resultEvaluation` and `result_criterium` tables exist in Roble.
  /// Roble does not auto-create tables on insert — they must be created explicitly.
  /// Called once before the first save attempt; uses try-catch so it never blocks
  /// the submission flow even if the create-table call fails or the table already exists.
  Future<void> _ensureResultTablesExist() async {
    // resultEvaluation — one record per evaluator→evaluated pair.
    bool resultEvalExists = false;
    try {
      await _db.robleRead(RobleTables.resultEvaluation);
      resultEvalExists = true;
    } catch (_) {}

    if (!resultEvalExists) {
      try {
        await _db.robleCreateTable(RobleTables.resultEvaluation, [
          {'name': 'resultEvaluation_id', 'type': 'text'},
          {'name': 'evaluation_id', 'type': 'text'},
          {'name': 'evaluator_id', 'type': 'text'},
          {'name': 'evaluated_id', 'type': 'text'},
          {'name': 'group_id', 'type': 'text'},
          {'name': 'comment', 'type': 'text'},
          {'name': 'created_at', 'type': 'text'},
        ]);
      } catch (_) {
        // Best-effort; subsequent insert will throw if table still missing.
      }
    }

    // result_criterium — per-criterion scores linked to resultEvaluation.
    bool resultCriteriumExists = false;
    try {
      await _db.robleRead(RobleTables.resultCriterium);
      resultCriteriumExists = true;
    } catch (_) {}

    if (!resultCriteriumExists) {
      try {
        await _db.robleCreateTable(RobleTables.resultCriterium, [
          {'name': 'result_id', 'type': 'text'},
          {'name': 'criterium_id', 'type': 'text'},
          {'name': 'score', 'type': 'text'},
        ]);
      } catch (_) {
        // Best-effort.
      }
    }
  }

  /// Reads the criterium table and returns a map of EvalCriterion.id to criterium_id UUID.
  /// Creates missing criterium rows so result_criterium FK references are valid.
  Future<Map<String, String>> _getOrCreateCriteriaMap() async {
    final rows = await _db.robleRead(RobleTables.criterium);
    final result = <String, String>{};

    for (final criterion in EvalCriterion.defaults) {
      Map<String, dynamic>? match;
      for (final row in rows) {
        final name = _asString(row['name']).toLowerCase();
        if (name == criterion.label.toLowerCase() ||
            name.contains(criterion.id.toLowerCase())) {
          match = row;
          break;
        }
      }

      if (match != null) {
        final criteriumId = _asString(match['criterium_id']);
        if (criteriumId.isNotEmpty) {
          result[criterion.id] = criteriumId;
          continue;
        }
      }

      // Not found — create so the FK in result_criterium is valid.
      try {
        final created = await _db.robleCreate(RobleTables.criterium, {
          'name': criterion.label,
          'description': criterion.label,
          'max_score': 5,
        });
        final criteriumId = _asString(created['criterium_id']);
        result[criterion.id] = criteriumId.isNotEmpty ? criteriumId : criterion.id;
      } catch (_) {
        result[criterion.id] = criterion.id; // best-effort fallback
      }
    }

    return result;
  }

  /// Finds a user's `user_id` UUID by their domain int ID.
  ///
  /// The domain int is computed with `stableNumericIdFromSeed(seed)` where seed
  /// follows the priority in auth_repository_impl: `id` → `_id` → `user_id` → email.
  /// We must try the same priority order to find a match, then return `user_id`
  /// (the canonical FK field used in all other tables).
  String _findUserUUIDByDomainId(
    List<Map<String, dynamic>> users,
    int domainId,
  ) {
    for (final u in users) {
      final userIdRef = _asString(u['user_id']);
      final seeds = <String>[
        _asString(u['id']),
        _asString(u['_id']),
        userIdRef,
        _asString(u['email']).toLowerCase(),
      ];
      for (final seed in seeds) {
        if (seed.isEmpty) continue;
        if (DatabaseService.stableNumericIdFromSeed(seed) == domainId) {
          return userIdRef.isNotEmpty ? userIdRef : _asString(u['_id']);
        }
      }
    }
    return '';
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
      id: _evalDomainId(row),
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
        id: _evalDomainId(row),
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
      if (_evalDomainId(row) != evalId &&
          _evalName(row).toLowerCase() == newName.toLowerCase()) {
        throw Exception('Ya existe una evaluación con ese nombre');
      }
    }

    final target = _findEvalById(teacherRows, evalId);
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
    final target = _findEvalById(evalRows, evalId);
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
    final eval = _findEvalById(evalRows, evalId);
    if (eval == null) return [];
    final evaluationUUID = _asString(eval['evaluation_id']);
    final categoryDomainId = _asInt(eval['category_id']);

    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);
    final users = await _db.robleRead(RobleTables.users);

    final usersByRef = <String, Map<String, dynamic>>{};
    for (final u in users) {
      final ref = _asString(u['user_id']);
      if (ref.isNotEmpty) usersByRef[ref] = u;
    }

    final inputGroups = <GroupResultsInputGroup>[];
    final inputMembers = <GroupResultsInputMember>[];

    for (final g in _groupsForCategoryDomain(allGroups, categoryDomainId)) {
      final groupRef = _asString(g['group_id']);
      final groupDomainId = DatabaseService.stableNumericIdFromSeed(groupRef);
      inputGroups.add(
        GroupResultsInputGroup(id: groupDomainId, name: _asString(g['name'])),
      );

      for (final m in _membersForGroup(allMembers, g)) {
        final memberDomainId = _memberDomainId(m);
        final userRef = _asString(m['user_id']);
        final user = usersByRef[userRef];
        final name = user != null
            ? _memberNameFromUsers(m, usersByRef)
            : _memberDisplayName(m);
        inputMembers.add(GroupResultsInputMember(
          groupId: groupDomainId,
          memberId: memberDomainId,
          name: name,
        ));
      }
    }

    // Read all resultEvaluation for this evaluation, then their result_criterium.
    final resultEvals = await _db.robleRead(
      RobleTables.resultEvaluation,
      filters: {'evaluation_id': evaluationUUID},
    );

    final inputResponses = <GroupResultsInputResponse>[];
    for (final re in resultEvals) {
      final reUUID = _asString(re['resultEvaluation_id']);
      final evaluatedUUID = _asString(re['evaluated_id']);
      if (reUUID.isEmpty || evaluatedUUID.isEmpty) continue;
      final evaluatedDomainId =
          DatabaseService.stableNumericIdFromSeed(evaluatedUUID);

      final criteriumRows = await _db.robleRead(
        RobleTables.resultCriterium,
        filters: {'result_id': reUUID},
      );
      for (final cr in criteriumRows) {
        inputResponses.add(GroupResultsInputResponse(
          evaluatedMemberId: evaluatedDomainId,
          criterionId: _asString(cr['criterium_id']),
          score: _asInt(cr['score']),
        ));
      }
    }

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
            id: _evalDomainId(row),
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
    final eval = _findEvalById(evalRows, evalId);
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
    final eval = _findEvalById(evalRows, evalId);
    if (eval == null) return [];

    final categoryId = _asInt(eval['category_id']);
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);
    final users = await _db.robleRead(RobleTables.users);

    // Build user lookup by user_id ref and email for name resolution.
    final usersByRef = <String, Map<String, dynamic>>{};
    for (final u in users) {
      for (final ref in [
        _asString(u['user_id']),
        _asString(u['email']).toLowerCase(),
      ]) {
        if (ref.isNotEmpty) usersByRef.putIfAbsent(ref, () => u);
      }
    }

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
          final name = _memberNameFromUsers(m, usersByRef);
          final peerId = _memberDomainId(m);
          return Peer(
            id: peerId.toString(),
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
    final resultEvals = await _db.robleRead(RobleTables.resultEvaluation);

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

    // Build completion map from resultEvaluation rows.
    // key = '$evalDomainId:$evaluatorDomainId', value = set of evaluatedDomainIds.
    final responseRowsByEvalAndEvaluator = <String, Set<int>>{};
    for (final row in resultEvals) {
      final evalUUID = _asString(row['evaluation_id']);
      final evaluatorUUID = _asString(row['evaluator_id']);
      final evaluatedUUID = _asString(row['evaluated_id']);
      if (evalUUID.isEmpty || evaluatorUUID.isEmpty || evaluatedUUID.isEmpty) {
        continue;
      }
      final evalDomainId = DatabaseService.stableNumericIdFromSeed(evalUUID);
      final evaluatorDomainId =
          DatabaseService.stableNumericIdFromSeed(evaluatorUUID);
      final evaluatedDomainId =
          DatabaseService.stableNumericIdFromSeed(evaluatedUUID);
      final key = '$evalDomainId:$evaluatorDomainId';
      responseRowsByEvalAndEvaluator
          .putIfAbsent(key, () => <int>{})
          .add(evaluatedDomainId);
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
        final activeEvalId = activeEval == null ? 0 : _evalDomainId(activeEval);
        final activeEvalName = activeEval == null ? '' : _evalName(activeEval);

        // Peer IDs for completion tracking — use the same domain ID as
        // getPeersForStudent so the values match evaluated_member_id in DB.
        final peerMemberIds = groupMembers
            .where((m) => !_isMembershipForStudent(
                  m, normalized, studentUserId,
                  studentRawUserId: identity.rawUserId,
                ))
            .map(_memberDomainId)
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
    await _ensureResultTablesExist();

    // 1. Find evaluation UUID and category domain ID.
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final evalRow = _findEvalById(evalRows, evalId);
    if (evalRow == null) throw Exception('Evaluación no encontrada');
    final evaluationUUID = _asString(evalRow['evaluation_id']);
    final categoryDomainId = _asInt(evalRow['category_id']);

    // 2. Reverse-lookup evaluator and evaluated user_id UUIDs from domain ints.
    final users = await _db.robleRead(RobleTables.users);
    final evaluatorUUID = _findUserUUIDByDomainId(users, evaluatorStudentId);
    final evaluatedUUID = _findUserUUIDByDomainId(users, evaluatedMemberId);
    if (evaluatorUUID.isEmpty || evaluatedUUID.isEmpty) {
      throw Exception('No se encontraron los usuarios');
    }

    // 3. Find group UUID containing both users.
    final allGroups = await _db.robleRead(RobleTables.groups);
    final allMembers = await _db.robleRead(RobleTables.userGroup);
    var groupUUID = '';
    for (final g in _groupsForCategoryDomain(allGroups, categoryDomainId)) {
      final gMembers = _membersForGroup(allMembers, g);
      final hasEv = gMembers.any((m) => _asString(m['user_id']) == evaluatorUUID);
      final hasEd = gMembers.any((m) => _asString(m['user_id']) == evaluatedUUID);
      if (hasEv && hasEd) {
        groupUUID = _asString(g['group_id']);
        break;
      }
    }

    // 4. Upsert resultEvaluation — one record per evaluator→evaluated pair.
    var resultEvalUUID = '';
    final existing = await _db.robleRead(
      RobleTables.resultEvaluation,
      filters: {
        'evaluation_id': evaluationUUID,
        'evaluator_id': evaluatorUUID,
        'evaluated_id': evaluatedUUID,
      },
    );
    if (existing.isNotEmpty) {
      resultEvalUUID = _asString(existing.first['resultEvaluation_id']);
    } else {
      final created = await _db.robleCreate(RobleTables.resultEvaluation, {
        'evaluation_id': evaluationUUID,
        'evaluator_id': evaluatorUUID,
        'evaluated_id': evaluatedUUID,
        'group_id': groupUUID,
        'comment': '',
        'created_at': DateTime.now().toIso8601String(),
      });
      resultEvalUUID = _asString(created['resultEvaluation_id']);
    }
    if (resultEvalUUID.isEmpty) return;

    // 5. Map EvalCriterion short IDs to criterium_id UUIDs.
    final criteriaMap = await _getOrCreateCriteriaMap();

    // 6. Idempotent writes to result_criterium.
    final existingScores = await _db.robleRead(
      RobleTables.resultCriterium,
      filters: {'result_id': resultEvalUUID},
    );
    final existingBycriteriumId = <String, String>{}; // criterium_id → _id
    for (final row in existingScores) {
      final cid = _asString(row['criterium_id']);
      final key = _asString(row['_id']);
      if (cid.isNotEmpty && key.isNotEmpty) existingBycriteriumId[cid] = key;
    }

    for (final entry in scores.entries) {
      final criteriumId = criteriaMap[entry.key] ?? entry.key;
      final score = entry.value;
      final existingKey = existingBycriteriumId[criteriumId];
      if (existingKey != null) {
        await _db.robleUpdate(
          RobleTables.resultCriterium,
          existingKey,
          {'score': score},
        );
      } else {
        await _db.robleCreate(RobleTables.resultCriterium, {
          'result_id': resultEvalUUID,
          'criterium_id': criteriumId,
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
    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final evalRow = _findEvalById(evalRows, evalId);
    if (evalRow == null) return false;
    final evaluationUUID = _asString(evalRow['evaluation_id']);

    final users = await _db.robleRead(RobleTables.users);
    final evaluatorUUID = _findUserUUIDByDomainId(users, evaluatorStudentId);
    final evaluatedUUID = _findUserUUIDByDomainId(users, evaluatedMemberId);
    if (evaluatorUUID.isEmpty || evaluatedUUID.isEmpty) return false;

    final rows = await _db.robleRead(
      RobleTables.resultEvaluation,
      filters: {
        'evaluation_id': evaluationUUID,
        'evaluator_id': evaluatorUUID,
        'evaluated_id': evaluatedUUID,
      },
    );
    return rows.isNotEmpty;
  }

  @override
  Future<List<CriterionResult>> getMyResults(int evalId, String email) async {
    final identity = await _resolveStudentIdentity(email);

    final evalRows = await _db.robleRead(RobleTables.evaluation);
    final eval = _findEvalById(evalRows, evalId);
    if (eval == null) return [];
    final evaluationUUID = _asString(eval['evaluation_id']);

    final myUUID = identity.rawUserId;
    if (myUUID.isEmpty) return [];

    // Find all resultEvaluation records where I am the evaluated person.
    final resultEvals = await _db.robleRead(
      RobleTables.resultEvaluation,
      filters: {'evaluation_id': evaluationUUID, 'evaluated_id': myUUID},
    );
    if (resultEvals.isEmpty) return [];

    // Build a reverse map: criterium_id UUID → EvalCriterion short id
    // so scores can be aggregated per EvalCriterion.
    final criteriaMap = await _getOrCreateCriteriaMap();
    final criteriumIdToShortId = {
      for (final entry in criteriaMap.entries) entry.value: entry.key,
    };

    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final re in resultEvals) {
      final reUUID = _asString(re['resultEvaluation_id']);
      if (reUUID.isEmpty) continue;

      final criteriumRows = await _db.robleRead(
        RobleTables.resultCriterium,
        filters: {'result_id': reUUID},
      );
      for (final r in criteriumRows) {
        final cUUID = _asString(r['criterium_id']);
        final score = _asInt(r['score']);
        if (score < 2) continue;
        // Prefer the short id for grouping; fall back to the UUID itself.
        final key = criteriumIdToShortId[cUUID] ?? cUUID;
        sums[key] = (sums[key] ?? 0) + score;
        counts[key] = (counts[key] ?? 0) + 1;
      }
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
    final eval = _findEvalById(evalRows, evalId);
    if (eval == null) return false;
    final evaluationUUID = _asString(eval['evaluation_id']);

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

    // Collect peer user_id UUIDs (exclude self).
    final peerUUIDs = myGroupMembers
        .where((m) => !_matchesStudentMembership(m, identity))
        .map((m) => _asString(m['user_id']))
        .where((ref) => ref.isNotEmpty)
        .toSet();
    if (peerUUIDs.isEmpty) return false;

    final evaluatorUUID = identity.rawUserId;
    if (evaluatorUUID.isEmpty) return false;

    // A resultEvaluation record per completed peer evaluation.
    final responses = await _db.robleRead(
      RobleTables.resultEvaluation,
      filters: {'evaluation_id': evaluationUUID, 'evaluator_id': evaluatorUUID},
    );

    final evaluatedUUIDs =
        responses.map((r) => _asString(r['evaluated_id'])).toSet();
    return peerUUIDs.every(evaluatedUUIDs.contains);
  }

  // ── TEST ───────────────────────────────────────────────────────────────────

  @override
  Future<void> testSaveSubmit({
    required String evaluatorEmail,
    required Map<String, Map<String, int>> scoresByPeerName,
  }) async {
    await _db.robleCreate('test_submit', {
      'evaluator_email': evaluatorEmail,
      'scores': scoresByPeerName.toString(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<List<Map<String, dynamic>>> readTestTable() async {
    return _db.robleRead('test_submit');
  }
}
