import 'package:example/data/services/database_service.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_course_repository.dart';

class CourseRepositoryImpl implements ICourseRepository {
  final DatabaseService _db;
  CourseRepositoryImpl(this._db);

  @override
  Future<List<CourseModel>> getAll(int teacherId) async {
    final db   = await _db.database;
    final rows = await db.query(
      'courses',
      where:   'teacher_id = ?',
      whereArgs: [teacherId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map((r) => CourseModel.fromMap(r.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<CourseModel> create({
    required String name,
    required String code,
    required int teacherId,
  }) async {
    final db  = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id  = await db.insert('courses', {
      'teacher_id': teacherId,
      'name':       name,
      'code':       code,
      'created_at': now,
    });
    return CourseModel(
      id:        id,
      teacherId: teacherId,
      name:      name,
      code:      code,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  @override
  Future<void> delete(int courseId) async {
    final db = await _db.database;
    await db.delete('courses', where: 'id = ?', whereArgs: [courseId]);
  }

  @override
  Future<List<GroupCategory>> getCategoriesForCourse(int courseId) async {
    final db      = await _db.database;
    final catRows = await db.query(
      'group_categories',
      where:   'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'imported_at DESC',
    );
    final result = <GroupCategory>[];
    for (final cat in catRows) {
      final catId   = cat['id'] as int;
      final grpRows = await db.query(
        'groups',
        where:   'category_id = ?',
        whereArgs: [catId],
        orderBy: 'name ASC',
      );
      final groups = <CourseGroup>[];
      for (final grp in grpRows) {
        final grpId   = grp['id'] as int;
        final memRows = await db.query(
          'group_members',
          where:   'group_id = ?',
          whereArgs: [grpId],
        );
        final members = memRows
            .map((m) => GroupMember(
                  id:       m['id']       as int,
                  name:     m['name']     as String,
                  username: m['username'] as String,
                ))
            .toList();
        groups.add(CourseGroup(
          id:      grpId,
          name:    grp['name'] as String,
          members: members,
        ));
      }
      result.add(GroupCategory(
        id:         catId,
        name:       cat['name']       as String,
        importedAt: DateTime.fromMillisecondsSinceEpoch(cat['imported_at'] as int),
        groups:     groups,
        courseId:   cat['course_id']  as int? ?? 0,
      ));
    }
    return result;
  }
}
