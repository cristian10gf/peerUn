class CsvImportParsedMember {
  final String name;
  final String username; // normalized email used as login

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

  int get totalMembers =>
      groups.fold<int>(0, (sum, group) => sum + group.members.length);
}

class CsvImportDomainService {
  const CsvImportDomainService();

  CsvImportParseResult parse(String csvContent) {
    // Strip BOM if present.
    final content = csvContent.startsWith('\uFEFF')
        ? csvContent.substring(1)
        : csvContent;

    final lines = content
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) throw Exception('CSV vacío');

    final dataLines = lines.skip(1); // skip header row
    final groupsByName = <String, List<CsvImportParsedMember>>{};

    for (final line in dataLines) {
      // Use RFC-4180 compliant splitter to handle quoted commas.
      final columns = _splitCsvLine(line);
      if (columns.length < 7) continue;

      // Brightspace export format (9 columns):
      // 0 = Group Category Name
      // 1 = Group Name          ← used as group key
      // 2 = Group Code
      // 3 = Username            ← institutional email / login (fallback)
      // 4 = OrgDefinedId
      // 5 = First Name          ← used for display name
      // 6 = Last Name           ← used for display name
      // 7 = Email Address       ← preferred over Username when present
      // 8 = Group Enrollment Date
      final groupName = columns[1].trim();
      final username  = columns[3].trim().toLowerCase();
      final firstName = columns[5].trim();
      final lastName  = columns[6].trim();
      final emailCol  = columns.length > 7 ? columns[7].trim().toLowerCase() : '';

      // Prefer the explicit Email Address column (col 7); fall back to Username.
      final email    = emailCol.isNotEmpty ? emailCol : username;
      final fullName = '$firstName $lastName'.trim();

      if (groupName.isEmpty || email.isEmpty || fullName.isEmpty) continue;

      groupsByName
          .putIfAbsent(groupName, () => <CsvImportParsedMember>[])
          .add(CsvImportParsedMember(name: fullName, username: email));
    }

    if (groupsByName.isEmpty) throw Exception('Sin datos de grupos');

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

  /// RFC-4180 compliant CSV line splitter.
  ///
  /// Handles:
  ///   • Quoted fields containing commas: "Doe, Jane" → Doe, Jane
  ///   • Escaped double-quotes inside quoted fields: "" → "
  ///   • Unquoted fields
  List<String> _splitCsvLine(String line) {
    final result  = <String>[];
    final buffer  = StringBuffer();
    var inQuotes  = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        // Check for escaped quote ("" inside a quoted field).
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++; // consume the second quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    result.add(buffer.toString()); // last field
    return result;
  }
}
