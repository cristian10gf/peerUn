class GroupMember {
  final int id;
  final String name;     // "FIRST LAST"
  final String username; // institutional email

  const GroupMember({
    required this.id,
    required this.name,
    required this.username,
  });
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
}

class GroupCategory {
  final int id;
  final String name;
  final DateTime importedAt;
  final List<CourseGroup> groups;

  const GroupCategory({
    required this.id,
    required this.name,
    required this.importedAt,
    required this.groups,
  });

  int get groupCount   => groups.length;
  int get studentCount => groups.fold(0, (s, g) => s + g.members.length);
}
