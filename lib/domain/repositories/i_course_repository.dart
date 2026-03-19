import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';

abstract interface class ICourseRepository {
  /// Returns all courses for [teacherId] ordered by creation date desc.
  Future<List<CourseModel>> getAll(int teacherId);

  /// Creates and persists a new course.
  Future<CourseModel> create({
    required String name,
    required String code,
    required int teacherId,
  });

  /// Deletes a course. Categories keep their course_id (become orphaned).
  Future<void> delete(int courseId);

  /// Returns categories belonging to [courseId] with their groups and members.
  Future<List<GroupCategory>> getCategoriesForCourse(int courseId);
}
