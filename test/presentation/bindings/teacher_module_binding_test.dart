import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/bindings/teacher_module_binding.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/controller_spies.dart';
import '../../helpers/repository_fakes.dart';

void _registerModuleDependencies() {
  final evalRepo = FakeEvaluationRepository();
  final groupRepo = FakeGroupRepository();

  Get.put<TeacherSessionController>(SpyTeacherSessionController(), permanent: true);
  Get.put<ICourseRepository>(FakeCourseRepository(), permanent: true);
  Get.put<IGroupRepository>(groupRepo, permanent: true);
  Get.put<IEvaluationRepository>(evalRepo, permanent: true);
  Get.put<TeacherImportCsvUseCase>(TeacherImportCsvUseCase(groupRepo), permanent: true);
  Get.put<TeacherCreateEvaluationUseCase>(
    TeacherCreateEvaluationUseCase(evalRepo),
    permanent: true,
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  test('dependencies registers mapper and results controller', () {
    _registerModuleDependencies();

    expect(Get.isRegistered<TeacherResultsViewMapper>(), isFalse);
    expect(Get.isRegistered<TeacherResultsController>(), isFalse);

    TeacherModuleBinding().dependencies();

    expect(Get.isRegistered<TeacherResultsViewMapper>(), isTrue);
    expect(Get.isRegistered<TeacherResultsController>(), isTrue);
  });

  test('dependencies injects mapper from Get.find into results controller', () {
    _registerModuleDependencies();

    final mapper = _SentinelMapper();
    Get.put<TeacherResultsViewMapper>(mapper, permanent: true);

    TeacherModuleBinding().dependencies();

    final controller = Get.find<TeacherResultsController>();
    final vm = controller.overviewVm;

    expect(vm.overallAverageLabel, 'mapper-sentinel');
  });

  test('dependencies keeps existing teacher controller registrations intact', () {
    _registerModuleDependencies();

    final existingImportController = TeacherCourseImportController(
      Get.find<TeacherSessionController>(),
      Get.find<IGroupRepository>(),
      Get.find<ICourseRepository>(),
      Get.find<TeacherImportCsvUseCase>(),
    );
    Get.put<TeacherCourseImportController>(existingImportController, permanent: true);

    final existingEvaluationController = TeacherEvaluationController(
      Get.find<TeacherSessionController>(),
      existingImportController,
      Get.find<IEvaluationRepository>(),
      Get.find<TeacherCreateEvaluationUseCase>(),
    );
    Get.put<TeacherEvaluationController>(existingEvaluationController, permanent: true);

    TeacherModuleBinding().dependencies();

    expect(identical(Get.find<TeacherCourseImportController>(), existingImportController), isTrue);
    expect(identical(Get.find<TeacherEvaluationController>(), existingEvaluationController), isTrue);
  });
}

class _SentinelMapper extends TeacherResultsViewMapper {
  @override
  TeacherResultsOverviewVm buildOverview(List<dynamic> groups) {
    return const TeacherResultsOverviewVm(
      overallAverageLabel: 'mapper-sentinel',
      groupCountLabel: '0',
      groups: <TeacherResultsGroupCardVm>[],
      hasGroups: false,
    );
  }
}
