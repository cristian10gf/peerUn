import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/repository_fakes.dart';

void main() {
  test('deriveCategoryNameFromFilename removes timestamp suffix', () {
    final useCase = TeacherImportCsvUseCase(FakeGroupRepository());

    final value = useCase.deriveCategoryNameFromFilename(
      'Categoria_20260217225843.csv',
    );

    expect(value, 'Categoria');
  });
}
