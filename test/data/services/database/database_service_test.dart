import 'dart:convert';

import 'package:example/data/services/database/database_service.dart';
import 'package:flutter_test/flutter_test.dart';

String _encodeJwtSegment(Map<String, dynamic> json) {
  return base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
}

String _buildJwt(Map<String, dynamic> claims) {
  final header = _encodeJwtSegment(<String, dynamic>{
    'alg': 'none',
    'typ': 'JWT',
  });
  final payload = _encodeJwtSegment(claims);
  return '$header.$payload.signature';
}

void main() {
  test('stableNumericIdFromSeed parses numeric seeds directly', () {
    expect(DatabaseService.stableNumericIdFromSeed('12345'), 12345);
    expect(DatabaseService.stableNumericIdFromSeed('0007'), 7);
  });

  test('stableNumericIdFromSeed is deterministic for non numeric seeds', () {
    final first = DatabaseService.stableNumericIdFromSeed('user-abc');
    final second = DatabaseService.stableNumericIdFromSeed('user-abc');

    expect(first, equals(second));
    expect(first, greaterThanOrEqualTo(0));
  });

  test('decodeJwtClaims and roleFromAccessToken read role payload', () {
    final db = DatabaseService();
    final token = _buildJwt(<String, dynamic>{
      'sub': '42',
      'role': 'teacher',
      'name': 'Ana Teacher',
    });

    final claims = db.decodeJwtClaims(token);

    expect(claims['sub'], '42');
    expect(claims['role'], 'teacher');
    expect(claims['name'], 'Ana Teacher');
    expect(db.roleFromAccessToken(token), 'teacher');
  });

  test('studentDefaultPassword has a non-empty configured value', () {
    final db = DatabaseService();
    expect(db.studentDefaultPassword.trim(), isNotEmpty);
  });
}
