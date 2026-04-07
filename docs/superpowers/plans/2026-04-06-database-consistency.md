# Database Consistency Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the six data-integrity and silent-failure bugs in the Roble integration that can corrupt or lose data through normal UI use.

**Architecture:** All fixes are surgical — one class per task. No new abstractions introduced. Roble has no server-side transactions; we compensate with correct delete ordering, application-level rollback stacks, and idempotent writes.

**Tech Stack:** Flutter/Dart, GetX, `roble_api_database ^1.0.3`, `shared_preferences`, `flutter_test`

---

## File Map

| Task | File(s) modified | File(s) created |
|------|-----------------|-----------------|
| 1 | `lib/data/utils/value_parsers.dart` | `test/data/utils/value_parsers_test.dart` |
| 2 | `lib/data/repositories/evaluation_repository_impl.dart` | `test/data/repositories/evaluation_repository_impl_delete_test.dart` |
| 3 | `lib/data/repositories/evaluation_repository_impl.dart` | `test/data/repositories/evaluation_repository_impl_responses_test.dart` |
| 4 | `lib/data/repositories/group_repository_impl.dart` | `test/data/repositories/group_repository_impl_rollback_test.dart` |
| 5 | `lib/data/services/database/database_service_session.dart` | `test/data/services/database/database_service_session_test.dart` |
| 6 | `lib/presentation/controllers/teacher/teacher_evaluation_controller.dart`<br>`test/helpers/repository_fakes.dart` | *(add tests to existing `test/presentation/controllers/teacher_evaluation_controller_test.dart`)* |

---

## Task 1 — Fix `asInt()` returning hashCode as a fake ID

**Why:** `asInt()` is used in every repository to derive record IDs from Roble strings. When the string is non-numeric (a UUID like `"a3f1…"`), `hashCode.abs()` returns a random stable integer that can accidentally match a real record ID stored elsewhere, causing wrong-record reads/deletes. The safe fallback is the `fallback` parameter.

**Files:**
- Modify: `lib/data/utils/value_parsers.dart:5`
- Create: `test/data/utils/value_parsers_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/utils/value_parsers_test.dart
import 'package:example/data/utils/value_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asInt', () {
    test('returns int value as-is', () {
      expect(asInt(42), 42);
    });

    test('parses numeric string', () {
      expect(asInt('99'), 99);
    });

    test('returns fallback for null', () {
      expect(asInt(null), 0);
      expect(asInt(null, fallback: -1), -1);
    });

    test('returns fallback for non-numeric string — never hashCode', () {
      // A UUID-like string must NOT silently match any real ID.
      // hashCode of 'abc-123' is non-zero but meaningless; it must become 0.
      expect(asInt('abc-123'), 0);
      expect(asInt('abc-123', fallback: -1), -1);
    });

    test('returns fallback for empty string', () {
      expect(asInt(''), 0);
    });
  });

  group('rowIdFromMap', () {
    test('returns 0 for map with non-numeric _id', () {
      // UUID _id must not match real int-based domain IDs.
      expect(rowIdFromMap({'_id': 'a3f1bc22d9'}), 0);
    });

    test('parses numeric _id', () {
      expect(rowIdFromMap({'_id': '7'}), 7);
    });
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```
flutter test test/data/utils/value_parsers_test.dart -v
```

Expected: `asInt('abc-123')` returns `hashCode` value (non-zero), test FAILS on the `never hashCode` case.

- [ ] **Step 3: Apply fix**

In `lib/data/utils/value_parsers.dart`, change line 5 only:

```dart
// BEFORE
return int.tryParse(value.toString()) ?? value.toString().hashCode.abs();

// AFTER
return int.tryParse(value.toString()) ?? fallback;
```

The full file after the fix:

```dart
int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return fallback;
  return double.tryParse(value.toString()) ?? fallback;
}

String asString(dynamic value) => value?.toString() ?? '';

DateTime asDate(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsedInt);
    }
    final parsedDate = DateTime.tryParse(value);
    if (parsedDate != null) return parsedDate;
  }
  final millis = asInt(
    value,
    fallback: (fallback ?? DateTime.now()).millisecondsSinceEpoch,
  );
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

int rowIdFromMap(Map<String, dynamic> row) => asInt(row['id'] ?? row['_id']);
```

- [ ] **Step 4: Run test — verify it passes**

```
flutter test test/data/utils/value_parsers_test.dart -v
```

Expected: All 6 tests PASS.

- [ ] **Step 5: Analyze**

```
flutter analyze lib/data/utils/value_parsers.dart
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/data/utils/value_parsers.dart test/data/utils/value_parsers_test.dart
git commit -m "fix: asInt returns fallback for non-numeric strings, not hashCode"
```

---

## Task 2 — Fix evaluation delete: criteria orphaned when eval delete fails

**Why:** The current `delete()` deletes `evaluation_criterium` rows first, then deletes the `evaluation`. If the evaluation delete throws (network error, token expired), the criteria are already gone but the evaluation still exists in the DB — the teacher sees an evaluation in the UI but all student scores are lost. Reversing the order ensures that if eval delete fails, nothing is lost; if it succeeds, criteria cleanup is best-effort.

**Files:**
- Modify: `lib/data/repositories/evaluation_repository_impl.dart:376-395`
- Create: `test/data/repositories/evaluation_repository_impl_delete_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/repositories/evaluation_repository_impl_delete_test.dart
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake DB that can fail on evaluation delete and tracks all deletes.
class _FakeDb extends DatabaseService {
  bool failEvalDelete = false;
  final List<String> deletedKeys = [];

  final List<Map<String, dynamic>> _evals = [
    {'_id': 'eval-1', 'id': 10, 'title': 'Sprint 1'},
  ];

  final List<Map<String, dynamic>> _criteria = [
    {'_id': 'crit-1', 'eval_id': 10, 'criterion_id': 'c1', 'score': 4},
    {'_id': 'crit-2', 'eval_id': 10, 'criterion_id': 'c2', 'score': 3},
  ];

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final source = tableName == RobleTables.evaluation
        ? _evals
        : tableName == RobleTables.evaluationCriterium
            ? _criteria
            : const <Map<String, dynamic>>[];

    if (filters == null || filters.isEmpty) {
      return source.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    return source
        .where((r) => filters.entries.every(
              (e) => r[e.key].toString() == e.value.toString(),
            ))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> robleDelete(
    String tableName,
    dynamic id,
  ) async {
    if (failEvalDelete && tableName == RobleTables.evaluation) {
      throw Exception('Network error');
    }
    deletedKeys.add('$tableName:$id');
    return {};
  }
}

void main() {
  group('EvaluationRepositoryImpl.delete', () {
    test('deletes evaluation BEFORE criteria so a failure leaves criteria intact',
        () async {
      final db = _FakeDb()..failEvalDelete = true;
      final repo = EvaluationRepositoryImpl(db);

      // Should throw because evaluation delete fails.
      await expectLater(repo.delete(10), throwsException);

      // Criteria must NOT have been deleted — nothing orphaned.
      expect(db.deletedKeys, isEmpty,
          reason: 'No criteria should be deleted when eval delete fails');
    });

    test('deletes evaluation then cleans up criteria on success', () async {
      final db = _FakeDb();
      final repo = EvaluationRepositoryImpl(db);

      await repo.delete(10);

      // Evaluation deleted first.
      expect(db.deletedKeys.first, '${RobleTables.evaluation}:eval-1');
      // Criteria cleaned up after.
      expect(db.deletedKeys, contains('${RobleTables.evaluationCriterium}:crit-1'));
      expect(db.deletedKeys, contains('${RobleTables.evaluationCriterium}:crit-2'));
    });
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```
flutter test test/data/repositories/evaluation_repository_impl_delete_test.dart -v
```

Expected: First test FAILS because current code deletes criteria first (deletedKeys is non-empty after throw).

- [ ] **Step 3: Apply fix**

Replace the `delete` method in `lib/data/repositories/evaluation_repository_impl.dart` (lines 376–395):

```dart
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
```

- [ ] **Step 4: Run test — verify it passes**

```
flutter test test/data/repositories/evaluation_repository_impl_delete_test.dart -v
```

Expected: Both tests PASS.

- [ ] **Step 5: Run full test suite to check for regressions**

```
flutter test test/data/repositories/ -v
```

Expected: All passing.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/evaluation_repository_impl.dart \
        test/data/repositories/evaluation_repository_impl_delete_test.dart
git commit -m "fix: delete evaluation before criteria to prevent orphaned data on failure"
```

---

## Task 3 — Fix `saveResponses()` idempotency: prevent duplicate scores

**Why:** If a student submits their scores, then hits the back button and submits again, `saveResponses()` creates a second set of `evaluation_criterium` rows for the same `(eval_id, evaluator_id, evaluated_member_id, criterion_id)` tuple. Results then double-count scores. The fix loads existing responses once and updates them instead of creating new ones.

**Files:**
- Modify: `lib/data/repositories/evaluation_repository_impl.dart:902-918`
- Create: `test/data/repositories/evaluation_repository_impl_responses_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/repositories/evaluation_repository_impl_responses_test.dart
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeResponseDb extends DatabaseService {
  final List<Map<String, dynamic>> _rows = [];
  final List<String> createCalls = [];
  final List<String> updateCalls = [];

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    if (tableName != RobleTables.evaluationCriterium) return const [];
    if (filters == null || filters.isEmpty) {
      return _rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    return _rows
        .where((r) => filters.entries.every(
              (e) => r[e.key].toString() == e.value.toString(),
            ))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final row = Map<String, dynamic>.from(data)
      ..['_id'] = 'row-${_rows.length + 1}';
    _rows.add(row);
    createCalls.add(data['criterion_id'].toString());
    return row;
  }

  @override
  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final idx = _rows.indexWhere((r) => r['_id'] == id);
    if (idx != -1) _rows[idx] = {..._rows[idx], ...updates};
    updateCalls.add(id.toString());
    return _rows[idx == -1 ? 0 : idx];
  }
}

void main() {
  group('EvaluationRepositoryImpl.saveResponses', () {
    test('first submission creates new criterium rows', () async {
      final db = _FakeResponseDb();
      final repo = EvaluationRepositoryImpl(db);

      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 4, 'c2': 5},
      );

      expect(db.createCalls, containsAll(['c1', 'c2']));
      expect(db.updateCalls, isEmpty);
    });

    test('second submission updates existing rows — no duplicates created', () async {
      final db = _FakeResponseDb();
      final repo = EvaluationRepositoryImpl(db);

      // First submission.
      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 4, 'c2': 5},
      );
      db.createCalls.clear();
      db.updateCalls.clear();

      // Second submission with changed scores.
      await repo.saveResponses(
        evalId: 1,
        evaluatorStudentId: 2,
        evaluatedMemberId: 3,
        scores: {'c1': 3, 'c2': 5},
      );

      // Must update, not create new duplicates.
      expect(db.createCalls, isEmpty,
          reason: 'No new rows should be created on re-submit');
      expect(db.updateCalls, containsAll(['row-1', 'row-2']));

      // Total rows must still be 2.
      expect(db._rows.length, 2);
    });
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```
flutter test test/data/repositories/evaluation_repository_impl_responses_test.dart -v
```

Expected: Second test FAILS because current code creates new rows on re-submit (4 rows total, updateCalls empty).

- [ ] **Step 3: Apply fix**

Replace the `saveResponses` method in `lib/data/repositories/evaluation_repository_impl.dart` (lines 902–918):

```dart
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
```

- [ ] **Step 4: Run test — verify it passes**

```
flutter test test/data/repositories/evaluation_repository_impl_responses_test.dart -v
```

Expected: Both tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test test/data/repositories/ -v
```

Expected: All passing.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/evaluation_repository_impl.dart \
        test/data/repositories/evaluation_repository_impl_responses_test.dart
git commit -m "fix: saveResponses updates existing scores instead of creating duplicates"
```

---

## Task 4 — CSV import: rollback category + groups on phase failure

**Why:** `importCsv` has 6 phases. Phases 1–2 create auth accounts and user table rows (irreversible). Phase 3 creates a category. Phase 4 creates groups (one API call per group). If any group creation fails midway, the category exists in the DB but has fewer groups than the CSV intended — the teacher sees the import as successful, students are grouped incorrectly. The fix adds a rollback that deletes all created groups + the category when phase 4 throws.

**Files:**
- Modify: `lib/data/repositories/group_repository_impl.dart:436-500` (phases 3 and 4)
- Create: `test/data/repositories/group_repository_impl_rollback_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/data/repositories/group_repository_impl_rollback_test.dart
import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/data/services/roble_schema.dart';
import 'package:example/domain/services/csv_import_domain_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal CSV with 2 groups (Group A and Group B).
const _kCsv = '''Group Category Name,Group Name,Group Code,Username,OrgDefinedId,First Name,Last Name,Email Address,Group Enrollment Date
Parcial 1,Group A,,user1,1,Ana,Perez,ana@uni.edu,2026-01-01
Parcial 1,Group B,,user2,2,Bob,Smith,bob@uni.edu,2026-01-01
''';

class _FakeRollbackDb extends DatabaseService {
  /// Create fails once Group B is attempted (second group).
  int groupCreateCount = 0;
  bool failOnSecondGroup = false;

  final List<String> createdRefs = [];
  final List<String> deletedKeys = [];

  @override
  Future<Map<String, dynamic>?> readAuthTokens() async => {
        'access_token': 'teacher-token',
        'refresh_token': 'teacher-refresh',
      };

  @override
  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (tableName == RobleTables.category) {
      final ref = 'cat-ref-1';
      createdRefs.add('category:$ref');
      return {'_id': ref, 'category_id': ref, 'name': data['name']};
    }
    if (tableName == RobleTables.groups) {
      groupCreateCount++;
      if (failOnSecondGroup && groupCreateCount == 2) {
        throw Exception('Network failure on Group B');
      }
      final ref = 'grp-ref-$groupCreateCount';
      createdRefs.add('group:$ref');
      return {'_id': ref, 'group_id': ref, 'name': data['name']};
    }
    return {'_id': 'row-${DateTime.now().millisecondsSinceEpoch}'};
  }

  @override
  Future<Map<String, dynamic>> robleDelete(
    String tableName,
    dynamic id,
  ) async {
    deletedKeys.add('$tableName:$id');
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> robleBulkInsert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async => const [];

  @override
  Future<Map<String, dynamic>> robleSignupDirect({
    required String email,
    required String password,
    required String name,
  }) async => {'accessToken': 'student-token'};

  @override
  void setSessionTokens({
    required String accessToken,
    required String refreshToken,
  }) {}

  @override
  Map<String, dynamic> decodeJwtClaims(String token) => {'sub': 'uid-$token'};
}

void main() {
  group('GroupRepositoryImpl.importCsv rollback', () {
    test('rolls back category and first group when second group creation fails',
        () async {
      final db = _FakeRollbackDb()..failOnSecondGroup = true;
      final repo = GroupRepositoryImpl(db);

      await expectLater(
        repo.importCsv(_kCsv, 'Parcial 1', 1, 1),
        throwsException,
      );

      // Category must be deleted.
      expect(
        db.deletedKeys,
        contains('${RobleTables.category}:cat-ref-1'),
        reason: 'Category must be rolled back on group creation failure',
      );

      // The successfully created first group must also be deleted.
      expect(
        db.deletedKeys,
        contains('${RobleTables.groups}:grp-ref-1'),
        reason: 'Already-created groups must be rolled back',
      );
    });

    test('does NOT rollback on success — category and groups persist', () async {
      final db = _FakeRollbackDb();
      final repo = GroupRepositoryImpl(db);

      final result = await repo.importCsv(_kCsv, 'Parcial 1', 1, 1);

      expect(db.deletedKeys, isEmpty);
      expect(result.groups.length, 2);
    });
  });
}
```

- [ ] **Step 2: Run test — verify it fails**

```
flutter test test/data/repositories/group_repository_impl_rollback_test.dart -v
```

Expected: First test FAILS because current code does not rollback (deletedKeys is empty after the exception).

- [ ] **Step 3: Apply fix**

In `lib/data/repositories/group_repository_impl.dart`, replace the phase 3 and phase 4 block. Find this section starting at `// ── PHASE 3`:

```dart
    // ── PHASE 3: Create category ─────────────────────────────────────────────
    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseReference,
    });
    final categoryReference = _categoryRef(catRow);
    final catId = _domainId(categoryReference, fallback: rowIdFromMap(catRow));

    // ── PHASE 4: Create groups + collect relation records ────────────────────
    final groups = <CourseGroup>[];
    final userGroupRecords = <Map<String, dynamic>>[];
    final userCourseRecords = <Map<String, dynamic>>[];

    for (final group in parsed.groups) {
      final grpRow = await _db.robleCreate(RobleTables.groups, {
        'category_id': categoryReference,
        'name': group.name,
      });
```

Replace the entire section through the end of Phase 4 with:

```dart
    // ── PHASE 3: Create category ─────────────────────────────────────────────
    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate(RobleTables.category, {
      'name': categoryName,
      'description': 'Importado desde CSV',
      'course_id': courseReference,
    });
    final categoryReference = _categoryRef(catRow);
    final catId = _domainId(categoryReference, fallback: rowIdFromMap(catRow));
    final catDbKey = catRow['_id']?.toString() ?? '';

    // ── PHASE 4: Create groups + collect relation records ────────────────────
    // If any group creation fails, rollback all created groups and the category
    // so the DB is not left with a half-populated import.
    final groups = <CourseGroup>[];
    final userGroupRecords = <Map<String, dynamic>>[];
    final userCourseRecords = <Map<String, dynamic>>[];
    final createdGroupKeys = <String>[]; // rollback stack

    try {
      for (final group in parsed.groups) {
        final grpRow = await _db.robleCreate(RobleTables.groups, {
          'category_id': categoryReference,
          'name': group.name,
        });
        final grpDbKey = grpRow['_id']?.toString() ?? '';
        if (grpDbKey.isNotEmpty) createdGroupKeys.add(grpDbKey);

        final groupReference = _groupRef(grpRow);
        final grpId = _domainId(groupReference, fallback: rowIdFromMap(grpRow));

        final members = <GroupMember>[];
        for (final member in group.members) {
          final studentEmail = normalizeEmail(member.username);
          final userRow = usersByEmail[studentEmail];
          final userReference = _asString(userRow?['user_id']).isNotEmpty
              ? _asString(userRow!['user_id'])
              : (authIdByEmail[studentEmail] ?? studentEmail);
          final userId = _domainId(
            userReference,
            fallback: asInt(userRow?['id'] ?? userRow?['_id']),
          );

          if (hasUserGroupTable) {
            final ugKey = '$groupReference::$userReference';
            if (!existingUserGroupKeys.contains(ugKey)) {
              userGroupRecords.add({
                'group_id': groupReference,
                'user_id': userReference,
              });
              existingUserGroupKeys.add(ugKey);
            }
          }

          if (hasUserCourseTable) {
            final ucKey = '$courseReference::$userReference';
            if (!existingUserCourseKeys.contains(ucKey)) {
              userCourseRecords.add({
                'course_id': courseReference,
                'user_id': userReference,
                'role': 'student',
              });
              existingUserCourseKeys.add(ucKey);
            }
          }

          members.add(
            GroupMember(id: userId, name: member.name, username: studentEmail),
          );
        }

        groups.add(CourseGroup(id: grpId, name: group.name, members: members));
      }
    } catch (e) {
      // Rollback: delete created groups in reverse order, then the category.
      for (final key in createdGroupKeys.reversed) {
        try {
          await _db.robleDelete(RobleTables.groups, key);
        } catch (_) {}
      }
      if (catDbKey.isNotEmpty) {
        try {
          await _db.robleDelete(RobleTables.category, catDbKey);
        } catch (_) {}
      }
      rethrow;
    }
```

- [ ] **Step 4: Run test — verify it passes**

```
flutter test test/data/repositories/group_repository_impl_rollback_test.dart -v
```

Expected: Both tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test test/data/repositories/ -v
```

Expected: All passing.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/group_repository_impl.dart \
        test/data/repositories/group_repository_impl_rollback_test.dart
git commit -m "fix: rollback category and groups on CSV import phase 4 failure"
```

---

## Task 5 — Fix session isolation: clear opposing role when saving session

**Why:** `saveStudentSession` and `saveTeacherSession` write to separate SharedPreferences keys without clearing the other role's key. After a teacher logs in, logs out, and a student logs in on the same device, both session keys exist in SharedPreferences simultaneously. The splash screen's parallel check (main.dart) may then route to the wrong home screen for the wrong role if the teacher session is stale but non-empty.

**Files:**
- Modify: `lib/data/services/database/database_service_session.dart:26-52`
- Create: `test/data/services/database/database_service_session_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run test — verify it fails**

```
flutter test test/data/services/database/database_service_session_test.dart -v
```

Expected: Both tests FAIL because teacher/student session key is NOT removed.

- [ ] **Step 3: Apply fix**

Replace the two `save*Session` methods in `lib/data/services/database/database_service_session.dart`:

```dart
Future<void> saveStudentSession(Map<String, dynamic> session) async {
  final prefs = await SharedPreferences.getInstance();
  // Clear the opposing role's session to prevent stale role data.
  await prefs.remove(teacherSessionKey);
  await prefs.setString(studentSessionKey, jsonEncode(session));
  final accessToken = session['access_token']?.toString() ?? '';
  final refreshToken = session['refresh_token']?.toString() ?? '';
  if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
    await saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: session['role']?.toString(),
    );
  }
}

Future<void> saveTeacherSession(Map<String, dynamic> session) async {
  final prefs = await SharedPreferences.getInstance();
  // Clear the opposing role's session to prevent stale role data.
  await prefs.remove(studentSessionKey);
  await prefs.setString(teacherSessionKey, jsonEncode(session));
  final accessToken = session['access_token']?.toString() ?? '';
  final refreshToken = session['refresh_token']?.toString() ?? '';
  if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
    await saveAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: session['role']?.toString(),
    );
  }
}
```

- [ ] **Step 4: Run test — verify it passes**

```
flutter test test/data/services/database/database_service_session_test.dart -v
```

Expected: Both tests PASS.

- [ ] **Step 5: Run full test suite**

```
flutter test test/ -v
```

Expected: All passing.

- [ ] **Step 6: Commit**

```bash
git add lib/data/services/database/database_service_session.dart \
        test/data/services/database/database_service_session_test.dart
git commit -m "fix: clear opposing role session key when saving new session"
```

---

## Task 6 — Fix controller: rename/delete evaluations without error handling

**Why:** `renameEvaluation()` and `deleteEvaluation()` in `TeacherEvaluationController` call the repository without try-catch. If the network throws, Flutter throws an unhandled exception, the UI freezes, and the in-memory `evaluations` list diverges from the DB. The fix wraps both in try-catch and sets `evalError` — the same pattern used by `createEvaluation()`.

**Files:**
- Modify: `lib/presentation/controllers/teacher/teacher_evaluation_controller.dart:142-171`
- Modify: `test/helpers/repository_fakes.dart` (add rename/delete error support)
- Modify: `test/presentation/controllers/teacher_evaluation_controller_test.dart` (add tests)

- [ ] **Step 1: Update `FakeEvaluationRepository` to support rename/delete errors**

In `test/helpers/repository_fakes.dart`, add two new error fields to `FakeEvaluationRepository` and wire them into `rename` and `delete`:

```dart
// Add these two fields to FakeEvaluationRepository (after existing fields):
Object? renameError;
Object? deleteError;
```

Update the `rename` method (currently around line 212):

```dart
@override
Future<void> rename(int evalId, String newName, int teacherId) async {
  if (renameError != null) throw renameError!;
  final index = evaluations.indexWhere((e) => e.id == evalId);
  if (index == -1) return;
  final old = evaluations[index];
  evaluations[index] = Evaluation(
    id: old.id,
    name: newName,
    categoryId: old.categoryId,
    categoryName: old.categoryName,
    courseName: old.courseName,
    hours: old.hours,
    visibility: old.visibility,
    createdAt: old.createdAt,
    closesAt: old.closesAt,
  );
}
```

Update the `delete` method (currently around line 159):

```dart
@override
Future<void> delete(int evalId) async {
  if (deleteError != null) throw deleteError!;
  evaluations = evaluations.where((e) => e.id != evalId).toList();
}
```

- [ ] **Step 2: Write the failing tests**

Add the following test cases to `test/presentation/controllers/teacher_evaluation_controller_test.dart`:

```dart
// Append inside the main() function:

test('renameEvaluation sets evalError on repository failure', () async {
  final evalRepo = FakeEvaluationRepository();
  evalRepo.evaluations = [
    Evaluation(
      id: 1,
      name: 'Sprint 1',
      categoryId: 10,
      categoryName: 'Grupo A',
      hours: 48,
      visibility: 'private',
      createdAt: DateTime(2026, 1, 1),
      closesAt: DateTime(2026, 1, 3),
    ),
  ];
  evalRepo.renameError = Exception('Network error');

  final groupRepo = FakeGroupRepository();
  final courseRepo = FakeCourseRepository();
  final session = SpyTeacherSessionController();
  session.setTeacherSession(
    const Teacher(id: '15', name: 'Doc', email: 'doc@uni.edu', initials: 'DO'),
  );

  final importCtrl = TeacherCourseImportController(
    session, groupRepo, courseRepo, TeacherImportCsvUseCase(groupRepo),
  );
  final ctrl = TeacherEvaluationController(
    session, importCtrl, evalRepo, TeacherCreateEvaluationUseCase(evalRepo),
  );
  ctrl.evaluations.assignAll(evalRepo.evaluations);

  await ctrl.renameEvaluation(1, 'Sprint 1 v2');

  expect(ctrl.evalError.value, isNotEmpty,
      reason: 'evalError must be set when rename fails');
  // In-memory name must NOT change when DB call failed.
  expect(ctrl.evaluations.first.name, 'Sprint 1',
      reason: 'In-memory state must stay unchanged on failure');
});

test('deleteEvaluation sets evalError on repository failure', () async {
  final evalRepo = FakeEvaluationRepository();
  evalRepo.evaluations = [
    Evaluation(
      id: 2,
      name: 'Sprint 2',
      categoryId: 10,
      categoryName: 'Grupo A',
      hours: 48,
      visibility: 'private',
      createdAt: DateTime(2026, 1, 1),
      closesAt: DateTime(2026, 1, 3),
    ),
  ];
  evalRepo.deleteError = Exception('DB locked');

  final groupRepo = FakeGroupRepository();
  final courseRepo = FakeCourseRepository();
  final session = SpyTeacherSessionController();
  session.setTeacherSession(
    const Teacher(id: '15', name: 'Doc', email: 'doc@uni.edu', initials: 'DO'),
  );

  final importCtrl = TeacherCourseImportController(
    session, groupRepo, courseRepo, TeacherImportCsvUseCase(groupRepo),
  );
  final ctrl = TeacherEvaluationController(
    session, importCtrl, evalRepo, TeacherCreateEvaluationUseCase(evalRepo),
  );
  ctrl.evaluations.assignAll(evalRepo.evaluations);

  await ctrl.deleteEvaluation(2);

  expect(ctrl.evalError.value, isNotEmpty,
      reason: 'evalError must be set when delete fails');
  // Evaluation must NOT be removed from in-memory list when DB call failed.
  expect(ctrl.evaluations.length, 1,
      reason: 'In-memory list must stay unchanged on failure');
});
```

- [ ] **Step 3: Run tests — verify they fail**

```
flutter test test/presentation/controllers/teacher_evaluation_controller_test.dart -v
```

Expected: Two new tests FAIL with unhandled exception (no try-catch yet).

- [ ] **Step 4: Apply fix**

Replace `renameEvaluation` and `deleteEvaluation` in `lib/presentation/controllers/teacher/teacher_evaluation_controller.dart` (lines 142–171):

```dart
Future<void> renameEvaluation(int evalId, String newName) async {
  evalError.value = '';
  try {
    await _evalRepo.rename(evalId, newName, _teacherId);
    final idx = evaluations.indexWhere((e) => e.id == evalId);
    if (idx != -1) {
      final old = evaluations[idx];
      evaluations[idx] = Evaluation(
        id: old.id,
        name: newName,
        categoryId: old.categoryId,
        categoryName: old.categoryName,
        courseName: old.courseName,
        hours: old.hours,
        visibility: old.visibility,
        createdAt: old.createdAt,
        closesAt: old.closesAt,
      );
      if (activeEval.value?.id == evalId) {
        activeEval.value = evaluations[idx];
      }
    }
  } catch (e) {
    evalError.value = parseApiError(e, fallback: 'Error al renombrar la evaluación');
  }
}

Future<void> deleteEvaluation(int evalId) async {
  evalError.value = '';
  try {
    await _evalRepo.delete(evalId);
    evaluations.removeWhere((e) => e.id == evalId);
    if (activeEval.value?.id == evalId) {
      activeEval.value = evaluations.firstWhereOrNull((e) => e.isActive);
    }
  } catch (e) {
    evalError.value = parseApiError(e, fallback: 'Error al eliminar la evaluación');
  }
}
```

Also add the missing import at the top of `teacher_evaluation_controller.dart` (it already imports `error_parser.dart` from Task 0 in this session — verify it's present, add if not):

```dart
import 'package:example/data/utils/error_parser.dart';
```

- [ ] **Step 5: Run tests — verify they pass**

```
flutter test test/presentation/controllers/teacher_evaluation_controller_test.dart -v
```

Expected: All tests PASS (3 total: original + 2 new).

- [ ] **Step 6: Run full test suite + analyze**

```
flutter test test/ -v
flutter analyze lib/
```

Expected: All tests pass, no analysis issues.

- [ ] **Step 7: Commit**

```bash
git add lib/presentation/controllers/teacher/teacher_evaluation_controller.dart \
        test/helpers/repository_fakes.dart \
        test/presentation/controllers/teacher_evaluation_controller_test.dart
git commit -m "fix: wrap renameEvaluation and deleteEvaluation in try-catch with evalError reporting"
```

---

## Self-Review Checklist

**Spec coverage:**

| Requirement | Task |
|-------------|------|
| asInt() returning hashCode could match wrong records | Task 1 ✓ |
| Criteria orphaned when eval delete fails | Task 2 ✓ |
| Duplicate scores on re-submission | Task 3 ✓ |
| Orphaned category+groups on partial CSV import | Task 4 ✓ |
| Stale opposing-role session after role switch | Task 5 ✓ |
| Uncaught exceptions in rename/delete break UI state | Task 6 ✓ |

**No placeholders:** All steps contain complete code. No "implement later" or "similar to above."

**Type consistency:** `_FakeDb` pattern (extends DatabaseService) used in Tasks 2, 3, 4 — consistent with existing project test helper pattern. `FakeEvaluationRepository.renameError/deleteError` introduced in Task 6 matches existing `nextError` naming.

**Dependency check:** Task 6 uses `parseApiError` — already available from the error_parser.dart added in the prior session. The import is already in `teacher_evaluation_controller.dart`.
