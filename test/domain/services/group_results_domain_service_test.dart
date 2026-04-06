import 'package:example/domain/services/group_results_domain_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = GroupResultsDomainService();

  test('buildGroupResults computes average by valid scores >= 2', () {
    final groups = service.buildGroupResults(
      groups: const <GroupResultsInputGroup>[
        GroupResultsInputGroup(id: 1, name: 'G1'),
      ],
      members: const <GroupResultsInputMember>[
        GroupResultsInputMember(groupId: 1, memberId: 100, name: 'Ana'),
      ],
      responses: const <GroupResultsInputResponse>[
        GroupResultsInputResponse(
          evaluatedMemberId: 100,
          criterionId: 'punct',
          score: 5,
        ),
        GroupResultsInputResponse(
          evaluatedMemberId: 100,
          criterionId: 'commit',
          score: 4,
        ),
      ],
    );

    expect(groups.single.average, 4.5);
    expect(groups.single.students.single.score, 4.5);
  });
}
