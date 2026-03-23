class CsvImportSummary {
  final String categoryName;
  final int groupsCreated;
  final int studentsCreated;
  final int courseId;

  const CsvImportSummary({
    required this.categoryName,
    required this.groupsCreated,
    required this.studentsCreated,
    required this.courseId,
  });
}
