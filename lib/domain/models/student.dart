class Student {
  final String id;
  final String name;
  final String email;
  final String initials;

  const Student({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
  });

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id:       map['id'].toString(),
        name:     map['name']     as String,
        email:    map['email']    as String,
        initials: map['initials'] as String,
      );
}
