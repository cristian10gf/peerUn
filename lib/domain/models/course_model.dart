class CourseModel {
  final int id;
  final int teacherId;
  final String name;
  final String code; // e.g. "DM2026-10", can be empty
  final DateTime createdAt;

  const CourseModel({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.code,
    required this.createdAt,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id:        map['id']         as int,
      teacherId: map['teacher_id'] as int,
      name:      map['name']       as String,
      code:      (map['code']      as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherId': teacherId,
    'name': name,
    'code': code,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
    id:        j['id']        as int,
    teacherId: j['teacherId'] as int,
    name:      j['name']      as String,
    code:      (j['code']     as String?) ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int, isUtc: true),
  );
}
