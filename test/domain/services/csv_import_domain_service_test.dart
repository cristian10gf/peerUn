import 'package:example/domain/services/csv_import_domain_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = CsvImportDomainService();

  test('parse trims BOM and groups rows by group name', () {
    const csv = '\uFEFFnrc,group,x,username,x,first,last\n'
        '123,Grupo A,x,ana@uni.edu,x,Ana,Lopez\n'
        '123,Grupo A,x,luis@uni.edu,x,Luis,Ruiz\n';

    final parsed = service.parse(csv);

    expect(parsed.totalGroups, 1);
    expect(parsed.totalMembers, 2);
    expect(parsed.groups.single.members.first.username, 'ana@uni.edu');
  });
}
