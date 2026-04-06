// test/data/utils/value_parsers_test.dart
import 'package:example/data/utils/value_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asInt', () {
    test('returns int value as-is', () {
      expect(asInt(42), 42);
    });

    test('parses numeric string', () {
      expect(asInt('99'), 99);
    });

    test('returns fallback for null', () {
      expect(asInt(null), 0);
      expect(asInt(null, fallback: -1), -1);
    });

    test('returns fallback for non-numeric string — never hashCode', () {
      expect(asInt('abc-123'), 0);
      expect(asInt('abc-123', fallback: -1), -1);
    });

    test('returns fallback for empty string', () {
      expect(asInt(''), 0);
    });
  });

  group('rowIdFromMap', () {
    test('returns 0 for map with non-numeric _id', () {
      expect(rowIdFromMap({'_id': 'a3f1bc22d9'}), 0);
    });

    test('parses numeric _id', () {
      expect(rowIdFromMap({'_id': '7'}), 7);
    });
  });
}
