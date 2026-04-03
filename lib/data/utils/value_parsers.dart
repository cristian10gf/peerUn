int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? value.toString().hashCode.abs();
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value == null) return fallback;
  return double.tryParse(value.toString()) ?? fallback;
}

String asString(dynamic value) => value?.toString() ?? '';

DateTime asDate(dynamic value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsedInt = int.tryParse(value);
    if (parsedInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(parsedInt);
    }
    final parsedDate = DateTime.tryParse(value);
    if (parsedDate != null) return parsedDate;
  }
  final millis = asInt(
    value,
    fallback: (fallback ?? DateTime.now()).millisecondsSinceEpoch,
  );
  return DateTime.fromMillisecondsSinceEpoch(millis);
}

int rowIdFromMap(Map<String, dynamic> row) => asInt(row['id'] ?? row['_id']);
