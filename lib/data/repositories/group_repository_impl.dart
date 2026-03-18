import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';

class GroupRepositoryImpl implements IGroupRepository {
  final DatabaseService _db;
  GroupRepositoryImpl(this._db);

  // ── Fetch ──────────────────────────────────────────────────────────────────

  @override
  Future<List<GroupCategory>> getAll(int teacherId) async {
    final db         = await _db.database;
    final catRows    = await db.query('group_categories',
        where: 'teacher_id = ?', whereArgs: [teacherId], orderBy: 'imported_at DESC');
    final result     = <GroupCategory>[];

    for (final cat in catRows) {
      final catId    = cat['id'] as int;
      final grpRows  = await db.query('groups',
          where: 'category_id = ?', whereArgs: [catId], orderBy: 'name ASC');

      final groups   = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId  = grp['id'] as int;
        final memRows = await db.query('group_members',
            where: 'group_id = ?', whereArgs: [grpId]);

        final members = memRows
            .map((m) => GroupMember(
                  id:       m['id'] as int,
                  name:     m['name'] as String,
                  username: m['username'] as String,
                ))
            .toList();

        groups.add(CourseGroup(id: grpId, name: grp['name'] as String, members: members));
      }

      result.add(GroupCategory(
        id:         catId,
        name:       cat['name'] as String,
        importedAt: DateTime.fromMillisecondsSinceEpoch(cat['imported_at'] as int),
        groups:     groups,
      ));
    }
    return result;
  }

  // ── Import CSV ─────────────────────────────────────────────────────────────

  @override
  Future<GroupCategory> importCsv(String csvContent, String categoryName, int teacherId) async {
    final db = await _db.database;

    // Strip UTF-8 BOM if present
    final content = csvContent.startsWith('\uFEFF')
        ? csvContent.substring(1)
        : csvContent;

    final lines = content
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();

    // Skip header
    if (lines.isEmpty) throw Exception('CSV vacío');
    final dataLines = lines.skip(1).toList();

    // Parse rows: group by group name
    final groupMap = <String, List<_ParsedMember>>{};
    for (final line in dataLines) {
      final cols = line.split(',');
      if (cols.length < 7) continue;
      final grpName  = cols[1].trim();
      final username = cols[3].trim();
      final first    = cols[5].trim();
      final last     = cols[6].trim();
      final name     = '$first $last';
      groupMap.putIfAbsent(grpName, () => []).add(_ParsedMember(name: name, username: username));
    }

    if (groupMap.isEmpty) throw Exception('Sin datos de grupos');

    final now = DateTime.now().millisecondsSinceEpoch;

    return await db.transaction((txn) async {
      final catId = await txn.insert('group_categories', {
        'name':        categoryName,
        'imported_at': now,
        'teacher_id':  teacherId,
      });

      final groups = <CourseGroup>[];
      for (final entry in groupMap.entries) {
        final grpId = await txn.insert('groups', {
          'category_id': catId,
          'name':        entry.key,
        });

        final members = <GroupMember>[];
        for (final m in entry.value) {
          final mId = await txn.insert('group_members', {
            'group_id': grpId,
            'name':     m.name,
            'username': m.username,
          });
          // Register student with default password if not already registered
          await txn.rawInsert('''
            INSERT OR IGNORE INTO students (name, email, password, initials)
            VALUES (?, ?, ?, ?)
          ''', [
            m.name,
            m.username.toLowerCase(),
            _hash('evalun2026'),
            _buildInitials(m.name),
          ]);
          members.add(GroupMember(id: mId, name: m.name, username: m.username));
        }
        groups.add(CourseGroup(id: grpId, name: entry.key, members: members));
      }

      return GroupCategory(
        id:         catId,
        name:       categoryName,
        importedAt: DateTime.fromMillisecondsSinceEpoch(now),
        groups:     groups,
      );
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(int categoryId) async {
    final db = await _db.database;
    // Delete members → groups → category (no CASCADE in sqflite by default)
    final grpRows = await db.query('groups',
        columns: ['id'], where: 'category_id = ?', whereArgs: [categoryId]);
    for (final g in grpRows) {
      await db.delete('group_members',
          where: 'group_id = ?', whereArgs: [g['id']]);
    }
    await db.delete('groups',       where: 'category_id = ?', whereArgs: [categoryId]);
    await db.delete('group_categories', where: 'id = ?', whereArgs: [categoryId]);
  }
}

class _ParsedMember {
  final String name;
  final String username;
  const _ParsedMember({required this.name, required this.username});
}

String _hash(String password) =>
    sha256.convert(utf8.encode(password)).toString();

String _buildInitials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
