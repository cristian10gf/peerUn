class Evaluation {
  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final String courseName; // denormalized for display; '' when no course
  final int hours;
  final String visibility; // 'public' | 'private'
  final DateTime createdAt;
  final DateTime closesAt;

  const Evaluation({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    this.courseName = '',
    required this.hours,
    required this.visibility,
    required this.createdAt,
    required this.closesAt,
  });

  bool get isActive => DateTime.now().isBefore(closesAt);
}
