import 'dart:convert';

import 'package:roble_api_database/roble_api_database.dart';
import 'package:uuid/uuid.dart';

import 'package:example/data/services/roble_schema.dart';

class DatabaseServiceCrud {
  final RobleApiDataBase roble;
  final Map<String, String> tableNameCache;
  final Uuid uuid;

  const DatabaseServiceCrud({
    required this.roble,
    required this.tableNameCache,
    required this.uuid,
  });

  Future<void> robleCreateTable(
    String tableName,
    List<Map<String, dynamic>> columns,
  ) async {
    final resolved = await _resolveTableName(tableName);
    await roble.createTable(resolved, columns);
  }

  Future<dynamic> robleGetTableData(String tableName) async {
    final resolved = await _resolveTableName(tableName);
    return roble.getTableData(resolved);
  }

  Future<Map<String, dynamic>> robleCreate(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final resolvedTableName = await _resolveTableName(tableName);
    final payload = _normalizeFieldsForTable(resolvedTableName, data);
    final primaryField = _primaryKeyFieldForTable(resolvedTableName);

    if (primaryField != RobleFields.rowId) {
      if (!payload.containsKey(primaryField) || payload[primaryField] == null) {
        payload[primaryField] = uuid.v4();
      } else {
        payload[primaryField] = payload[primaryField].toString();
      }
    }

    final row = await roble.create(resolvedTableName, payload);

    final hasPrimaryKey = _rowHasPrimaryKey(row, resolvedTableName);
    if (hasPrimaryKey) return row;

    final skipped = row['skipped'];
    if (skipped is List && skipped.isNotEmpty) {
      final reason = (skipped.first is Map)
          ? (skipped.first['reason']?.toString() ?? skipped.first.toString())
          : skipped.first.toString();
      throw Exception('Insert rechazado en $resolvedTableName: $reason');
    }

    throw Exception(
      'Insert sin fila valida en $resolvedTableName. Respuesta: ${jsonEncode(row)}',
    );
  }

  Future<List<Map<String, dynamic>>> robleRead(
    String tableName, {
    Map<String, dynamic>? filters,
  }) async {
    final resolved = await _resolveTableName(tableName);
    final resolvedFilters =
        filters == null ? null : _normalizeFieldsForTable(resolved, filters);
    return roble.read(resolved, filters: resolvedFilters);
  }

  Future<Map<String, dynamic>?> robleFindUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();

    final direct =
        await robleRead(RobleTables.users, filters: {'email': normalized});
    if (direct.isNotEmpty) return direct.first;

    final allUsers = await robleRead(RobleTables.users);
    for (final user in allUsers) {
      final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
      if (userEmail == normalized) return user;
    }
    return null;
  }

  Future<Map<String, dynamic>> robleUpdate(
    String tableName,
    dynamic id,
    Map<String, dynamic> updates,
  ) async {
    final resolved = await _resolveTableName(tableName);
    final normalizedUpdates = _normalizeFieldsForTable(resolved, updates);
    return roble.update(resolved, id, normalizedUpdates);
  }

  Future<Map<String, dynamic>> robleDelete(String tableName, dynamic id) async {
    final resolved = await _resolveTableName(tableName);
    return roble.delete(resolved, id);
  }

  Future<String> _resolveTableName(String requestedName) async {
    final requested = requestedName.trim();
    if (requested.isEmpty) return requestedName;

    final cached = tableNameCache[requested];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final aliases = RobleSchema.tableAliases[requested] ?? <String>[requested];
    final seen = <String>{};
    final candidates = <String>[];
    for (final name in aliases) {
      final trimmed = name.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      candidates.add(trimmed);
    }

    for (final candidate in candidates) {
      try {
        await roble.read(candidate);
        tableNameCache[requested] = candidate;
        return candidate;
      } catch (_) {
        // Try next alias.
      }
    }

    tableNameCache[requested] = requested;
    return requested;
  }

  String _logicalTableKey(String tableName) {
    final requested = tableName.trim();
    if (requested.isEmpty) return tableName;

    for (final entry in RobleSchema.tableAliases.entries) {
      if (entry.key == requested || entry.value.contains(requested)) {
        return entry.key;
      }
    }
    return requested;
  }

  String _primaryKeyFieldForTable(String tableName) {
    final logical = _logicalTableKey(tableName);
    return RobleSchema.tablePrimaryKeys[logical] ?? '${logical}_id';
  }

  List<String> _primaryKeyAliasesForTable(String tableName) {
    final logical = _logicalTableKey(tableName);
    final primary = _primaryKeyFieldForTable(tableName);
    final aliases =
        RobleSchema.fieldAliasesByTable[logical]?[primary] ?? const <String>[];
    final seen = <String>{};
    final keys = <String>[];

    for (final key
        in <String>[primary, ...aliases, RobleFields.rowId, RobleFields.id]) {
      final trimmed = key.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) continue;
      seen.add(trimmed);
      keys.add(trimmed);
    }
    return keys;
  }

  bool _rowHasPrimaryKey(Map<String, dynamic> row, String tableName) {
    final candidates = _primaryKeyAliasesForTable(tableName);
    for (final key in candidates) {
      final value = row[key];
      if (value != null && value.toString().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic> _normalizeFieldsForTable(
    String tableName,
    Map<String, dynamic> source,
  ) {
    final logical = _logicalTableKey(tableName);
    final aliasesByCanonical = RobleSchema.fieldAliasesByTable[logical];
    if (aliasesByCanonical == null || aliasesByCanonical.isEmpty) {
      return Map<String, dynamic>.from(source);
    }

    final aliasToCanonical = <String, String>{};
    for (final entry in aliasesByCanonical.entries) {
      for (final alias in entry.value) {
        aliasToCanonical[alias] = entry.key;
      }
    }

    final canonicalPresent = <String>{};
    for (final key in source.keys) {
      if (aliasesByCanonical.containsKey(key)) {
        canonicalPresent.add(key);
      }
    }

    final normalized = <String, dynamic>{};
    for (final entry in source.entries) {
      final fromAlias = aliasToCanonical[entry.key];
      if (fromAlias != null && canonicalPresent.contains(fromAlias)) {
        continue;
      }
      final targetKey = fromAlias ?? entry.key;
      normalized.putIfAbsent(targetKey, () => entry.value);
    }

    return normalized;
  }
}
