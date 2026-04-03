class CsvImportParsedMember {
  final String name;
  final String username;

  const CsvImportParsedMember({
    required this.name,
    required this.username,
  });
}

class CsvImportParsedGroup {
  final String name;
  final List<CsvImportParsedMember> members;

  const CsvImportParsedGroup({
    required this.name,
    required this.members,
  });
}

class CsvImportParseResult {
  final List<CsvImportParsedGroup> groups;

  const CsvImportParseResult({required this.groups});

  int get totalGroups => groups.length;

  int get totalMembers {
    return groups.fold<int>(0, (sum, group) => sum + group.members.length);
  }
}

class CsvImportDomainService {
  const CsvImportDomainService();

  CsvImportParseResult parse(String csvContent) {
    final content = csvContent.startsWith('\uFEFF')
        ? csvContent.substring(1)
        : csvContent;

    final lines = content
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) {
      throw Exception('CSV vacio');
    }

    final dataLines = lines.skip(1);
    final groupsByName = <String, List<CsvImportParsedMember>>{};

    for (final line in dataLines) {
      final columns = line.split(',');
      if (columns.length < 7) continue;

      final groupName = columns[1].trim();
      final username = columns[3].trim().toLowerCase();
      final firstName = columns[5].trim();
      final lastName = columns[6].trim();
      final fullName = '$firstName $lastName'.trim();

      if (groupName.isEmpty || username.isEmpty || fullName.isEmpty) continue;

      groupsByName
          .putIfAbsent(groupName, () => <CsvImportParsedMember>[])
          .add(CsvImportParsedMember(name: fullName, username: username));
    }

    if (groupsByName.isEmpty) {
      throw Exception('Sin datos de grupos');
    }

    final groups = groupsByName.entries
        .map(
          (entry) => CsvImportParsedGroup(
            name: entry.key,
            members: entry.value,
          ),
        )
        .toList(growable: false);

    return CsvImportParseResult(groups: groups);
  }
}
