class Teacher {
  final String id;
  final String name;
  final String email;
  final String initials;

  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
  });

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
        id:       map['id'].toString(),
        name:     map['name']     as String,
        email:    map['email']    as String,
        initials: map['initials'] as String,
      );
}
