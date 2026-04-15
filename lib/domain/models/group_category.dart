class GroupMember {
  final int id;
  final String name;     // "FIRST LAST"
  final String username; // institutional email

  const GroupMember({
    required this.id,
    required this.name,
    required this.username,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
  };

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
    id: j['id'] as int,
    name: j['name'] as String,
    username: j['username'] as String,
  );
}

class CourseGroup {
  final int id;
  final String name; // "Group 1", "Group 2", …
  final List<GroupMember> members;

  const CourseGroup({
    required this.id,
    required this.name,
    required this.members,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'members': members.map((m) => m.toJson()).toList(),
  };

  factory CourseGroup.fromJson(Map<String, dynamic> j) => CourseGroup(
    id: j['id'] as int,
    name: j['name'] as String,
    members: (j['members'] as List)
        .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
        .toList(),
  );
}

class GroupCategory {
  final int id;
  final String name;
  final DateTime importedAt;
  final List<CourseGroup> groups;
  final int courseId; // 0 when not assigned to a course

  const GroupCategory({
    required this.id,
    required this.name,
    required this.importedAt,
    required this.groups,
    this.courseId = 0,
  });

  int get groupCount   => groups.length;
  int get studentCount => groups.fold(0, (s, g) => s + g.members.length);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'importedAt': importedAt.toIso8601String(),
    'groups': groups.map((g) => g.toJson()).toList(),
    'courseId': courseId,
  };

  factory GroupCategory.fromJson(Map<String, dynamic> j) => GroupCategory(
    id: j['id'] as int,
    name: j['name'] as String,
    importedAt: DateTime.parse(j['importedAt'] as String),
    groups: (j['groups'] as List)
        .map((g) => CourseGroup.fromJson(g as Map<String, dynamic>))
        .toList(),
    courseId: (j['courseId'] as int?) ?? 0,
  );
}
