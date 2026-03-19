import 'package:example/domain/models/group_category.dart';

abstract interface class IGroupRepository {
  Future<List<GroupCategory>> getAll(int teacherId);
  Future<GroupCategory> importCsv(
    String csvContent,
    String categoryName,
    int teacherId,
    int courseId,
  );
  Future<void> delete(int categoryId);
}
