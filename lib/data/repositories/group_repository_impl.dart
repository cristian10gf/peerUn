import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';

class GroupRepositoryImpl implements IGroupRepository {
  final DatabaseService _db;
  GroupRepositoryImpl(this._db);

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? value.toString().hashCode.abs();
  }

  int _rowId(Map<String, dynamic> row) => _asInt(row['id'] ?? row['_id']);

  DateTime _asDate(dynamic value) {
    final millis = _asInt(value, fallback: DateTime.now().millisecondsSinceEpoch);
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async {
    final catRows = await _db.robleRead(
      'group_categories',
      filters: {'teacher_id': teacherId},
    );

    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final catId = _rowId(cat);
      final grpRows = await _db.robleRead('groups', filters: {'category_id': catId});

      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId = _rowId(grp);
        final memRows = await _db.robleRead('group_members', filters: {'group_id': grpId});

        final members = memRows
            .map(
              (m) => GroupMember(
                id: _rowId(m),
                name: (m['name'] ?? '').toString(),
                username: (m['username'] ?? '').toString(),
              ),
            )
            .toList();

        groups.add(CourseGroup(
          id: grpId,
          name: (grp['name'] ?? '').toString(),
          members: members,
        ));
      }

      result.add(
        GroupCategory(
          id: catId,
          name: (cat['name'] ?? '').toString(),
          importedAt: _asDate(cat['imported_at']),
          groups: groups,
          courseId: _asInt(cat['course_id']),
        ),
      );
    }

    result.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return result;
  }

  @override
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  ) async {
    final content = csvContent.startsWith('\uFEFF') ? csvContent.substring(1) : csvContent;
    final lines = content
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) throw Exception('CSV vacio');
    final dataLines = lines.skip(1).toList();

    final groupMap = <String, List<_ParsedMember>>{};
    for (final line in dataLines) {
      final cols = line.split(',');
      if (cols.length < 7) continue;
      final grpName = cols[1].trim();
      final username = cols[3].trim().toLowerCase();
      final first = cols[5].trim();
      final last = cols[6].trim();
      final name = '$first $last'.trim();

      if (grpName.isEmpty || username.isEmpty || name.isEmpty) continue;
      groupMap.putIfAbsent(grpName, () => []).add(_ParsedMember(name: name, username: username));
    }

    if (groupMap.isEmpty) throw Exception('Sin datos de grupos');

    final now = DateTime.now().millisecondsSinceEpoch;
    final catRow = await _db.robleCreate('group_categories', {
      'name': categoryName,
      'imported_at': now,
      'teacher_id': teacherId,
      'course_id': courseId,
    });

    final catId = _rowId(catRow);
    final groups = <CourseGroup>[];

    for (final entry in groupMap.entries) {
      final grpRow = await _db.robleCreate('groups', {
        'category_id': catId,
        'name': entry.key,
      });

      final grpId = _rowId(grpRow);
      final members = <GroupMember>[];
      for (final m in entry.value) {
        final memberRow = await _db.robleCreate('group_members', {
          'group_id': grpId,
          'name': m.name,
          'username': m.username,
        });
        members.add(
          GroupMember(
            id: _rowId(memberRow),
            name: (memberRow['name'] ?? m.name).toString(),
            username: (memberRow['username'] ?? m.username).toString(),
          ),
        );
      }

      groups.add(CourseGroup(id: grpId, name: entry.key, members: members));
    }

    return GroupCategory(
      id: catId,
      name: categoryName,
      importedAt: DateTime.fromMillisecondsSinceEpoch(now),
      groups: groups,
      courseId: courseId,
    );
  }

  @override
  Future<void> delete(int categoryId) async {
    final catRows = await _db.robleRead('group_categories');
    Map<String, dynamic>? target;
    for (final row in catRows) {
      if (_rowId(row) == categoryId) {
        target = row;
        break;
      }
    }
    if (target == null) return;

    final grpRows = await _db.robleRead('groups', filters: {'category_id': categoryId});
    for (final grp in grpRows) {
      final grpId = _rowId(grp);
      final grpKey = grp['_id']?.toString();
      final memRows = await _db.robleRead('group_members', filters: {'group_id': grpId});
      for (final m in memRows) {
        final mk = m['_id']?.toString();
        if (mk != null && mk.isNotEmpty) {
          await _db.robleDelete('group_members', mk);
        }
      }
      if (grpKey != null && grpKey.isNotEmpty) {
        await _db.robleDelete('groups', grpKey);
      }
    }

    final catKey = target['_id']?.toString();
    if (catKey != null && catKey.isNotEmpty) {
      await _db.robleDelete('group_categories', catKey);
    }
  }
}

class _ParsedMember {
  final String name;
  final String username;
  const _ParsedMember({required this.name, required this.username});
}
