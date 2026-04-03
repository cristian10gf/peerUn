import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_group_repository.dart';

class TeacherImportCsvOutput {
  final GroupCategory category;
  final String categoryName;
  final int groupsCreated;
  final int studentsCreated;
  final int courseId;

  const TeacherImportCsvOutput({
    required this.category,
    required this.categoryName,
    required this.groupsCreated,
    required this.studentsCreated,
    required this.courseId,
  });
}

class TeacherImportCsvUseCase {
  final IGroupRepository _groupRepository;

  const TeacherImportCsvUseCase(this._groupRepository);

  String deriveCategoryNameFromFilename(String fileName) {
    final withoutCsv = fileName.replaceAll(
      RegExp(r'\.csv$', caseSensitive: false),
      '',
    );
    final categoryName = withoutCsv.replaceAll(RegExp(r'_\d{14}'), '').trim();
    return categoryName.isEmpty ? 'Importación sin nombre' : categoryName;
  }

  Future<TeacherImportCsvOutput> execute({
    required String csvContent,
    required String fileName,
    required int teacherId,
    required int courseId,
  }) async {
    if (csvContent.trim().isEmpty) {
      throw Exception('El archivo CSV está vacío');
    }

    final categoryName = deriveCategoryNameFromFilename(fileName);
    final category = await _groupRepository.importCsv(
      csvContent,
      categoryName,
      teacherId,
      courseId,
    );

    return TeacherImportCsvOutput(
      category: category,
      categoryName: category.name,
      groupsCreated: category.groupCount,
      studentsCreated: category.studentCount,
      courseId: courseId,
    );
  }
}
