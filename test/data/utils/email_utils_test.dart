import 'package:example/data/utils/email_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeEmail trims and lowercases full emails', () {
    final normalized = normalizeEmail('  USER.Name@UniNorte.edu.co  ');
    expect(normalized, 'user.name@uninorte.edu.co');
  });

  test('normalizeEmail appends default domain when missing', () {
    final normalized = normalizeEmail('student123');
    expect(normalized, 'student123@uninorte.edu.co');
  });

  test('normalizeEmail uses custom default domain when provided', () {
    final normalized = normalizeEmail(
      ' teacher.user ',
      defaultDomain: 'example.org',
    );
    expect(normalized, 'teacher.user@example.org');
  });
}
