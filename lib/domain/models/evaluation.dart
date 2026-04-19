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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'courseName': courseName,
    'hours': hours,
    'visibility': visibility,
    'createdAt': createdAt.toIso8601String(),
    'closesAt': closesAt.toIso8601String(),
  };

  factory Evaluation.fromJson(Map<String, dynamic> j) => Evaluation(
    id: j['id'] as int,
    name: j['name'] as String,
    categoryId: j['categoryId'] as int,
    categoryName: j['categoryName'] as String,
    courseName: (j['courseName'] as String?) ?? '',
    hours: j['hours'] as int,
    visibility: j['visibility'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    closesAt: DateTime.parse(j['closesAt'] as String),
  );
}
