// test/domain/models/json_serialization_test.dart
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/models/teacher_data.dart';

void main() {
  group('Evaluation JSON', () {
    test('roundtrip preserves all fields', () {
      final eval = Evaluation(
        id: 42,
        name: 'Sprint 1',
        categoryId: 7,
        categoryName: 'Grupo A',
        courseName: 'DM 2026',
        hours: 48,
        visibility: 'public',
        createdAt: DateTime.utc(2026, 1, 10, 8, 0),
        closesAt: DateTime.utc(2026, 1, 12, 8, 0),
      );
      final restored = Evaluation.fromJson(eval.toJson());
      expect(restored.id, 42);
      expect(restored.name, 'Sprint 1');
      expect(restored.categoryId, 7);
      expect(restored.categoryName, 'Grupo A');
      expect(restored.courseName, 'DM 2026');
      expect(restored.hours, 48);
      expect(restored.visibility, 'public');
      expect(restored.createdAt, DateTime.utc(2026, 1, 10, 8, 0));
      expect(restored.closesAt, DateTime.utc(2026, 1, 12, 8, 0));
    });

    test('courseName defaults to empty string when absent', () {
      final eval = Evaluation(
        id: 1, name: 'X', categoryId: 1, categoryName: 'C',
        hours: 1, visibility: 'private',
        createdAt: DateTime.utc(2026, 1, 1),
        closesAt: DateTime.utc(2026, 1, 2),
      );
      final json = eval.toJson();
      json.remove('courseName');
      expect(Evaluation.fromJson(json).courseName, '');
    });
  });

  group('CourseModel JSON', () {
    test('roundtrip preserves all fields', () {
      final course = CourseModel(
        id: 5,
        teacherId: 3,
        name: 'Diseño de Medios',
        code: 'DM2026',
        createdAt: DateTime.utc(2026, 2, 1),
      );
      final restored = CourseModel.fromJson(course.toJson());
      expect(restored.id, 5);
      expect(restored.teacherId, 3);
      expect(restored.name, 'Diseño de Medios');
      expect(restored.code, 'DM2026');
      expect(restored.createdAt, DateTime.utc(2026, 2, 1));
    });
  });

  group('GroupCategory JSON', () {
    test('roundtrip with nested groups and members', () {
      final cat = GroupCategory(
        id: 1,
        name: 'Brightspace G1',
        importedAt: DateTime.utc(2026, 3, 5),
        courseId: 10,
        groups: [
          CourseGroup(
            id: 2,
            name: 'Group 1',
            members: [
              const GroupMember(id: 100, name: 'Ana Perez', username: 'ana@uni.co'),
              const GroupMember(id: 101, name: 'Luis Gomez', username: 'luis@uni.co'),
            ],
          ),
        ],
      );
      final restored = GroupCategory.fromJson(cat.toJson());
      expect(restored.id, 1);
      expect(restored.courseId, 10);
      expect(restored.groups.length, 1);
      expect(restored.groups.first.members.length, 2);
      expect(restored.groups.first.members.first.username, 'ana@uni.co');
    });
  });

  group('StudentHomeCourse JSON', () {
    test('roundtrip with nested categories and groups', () {
      const member = GroupMember(id: 1, name: 'Ana', username: 'ana@uni.co');
      final group = StudentHomeGroup(id: 10, name: 'G1', members: [member]);
      final category = StudentHomeCategory(
        id: 20,
        name: 'Cat A',
        group: group,
        activeEvaluationId: 5,
        activeEvaluationName: 'Sprint 1',
        completedPeerCount: 1,
        totalPeerCount: 3,
      );
      final course = StudentHomeCourse(
        id: 99,
        name: 'DM',
        hasGroupAssignment: true,
        categories: [category],
      );
      final restored = StudentHomeCourse.fromJson(course.toJson());
      expect(restored.id, 99);
      expect(restored.categories.length, 1);
      expect(restored.categories.first.activeEvaluationId, 5);
      expect(restored.categories.first.group?.members.first.username, 'ana@uni.co');
    });

    test('category with null group roundtrips correctly', () {
      const cat = StudentHomeCategory(id: 1, name: 'No Group');
      final course = StudentHomeCourse(
        id: 1, name: 'X', hasGroupAssignment: false, categories: [cat],
      );
      final restored = StudentHomeCourse.fromJson(course.toJson());
      expect(restored.categories.first.group, isNull);
    });
  });

  group('GroupResult / StudentResult JSON', () {
    test('roundtrip with nested students', () {
      const result = GroupResult(
        name: 'Group A',
        average: 4.2,
        criteria: [4.0, 4.5, 4.1, 4.2],
        students: [
          StudentResult(initial: 'A', name: 'Ana', score: 4.3),
          StudentResult(initial: 'L', name: 'Luis', score: 4.1),
        ],
      );
      final restored = GroupResult.fromJson(result.toJson());
      expect(restored.name, 'Group A');
      expect(restored.average, closeTo(4.2, 0.001));
      expect(restored.criteria, [4.0, 4.5, 4.1, 4.2]);
      expect(restored.students.length, 2);
      expect(restored.students.first.score, closeTo(4.3, 0.001));
    });
  });
}
