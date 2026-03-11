import 'package:example/domain/models/group_category.dart';

abstract interface class IGroupRepository {
  Future<List<GroupCategory>> getAll();
  Future<GroupCategory> importCsv(String csvContent, String categoryName);
  Future<void> delete(int categoryId);
}
