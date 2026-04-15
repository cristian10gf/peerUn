import 'package:get/get.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';

class TeacherModuleBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TeacherCourseImportController>()) {
      Get.put<TeacherCourseImportController>(
        TeacherCourseImportController(
          Get.find<TeacherSessionController>(),
          Get.find<IGroupRepository>(),
          Get.find<ICourseRepository>(),
          Get.find<TeacherImportCsvUseCase>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TeacherEvaluationController>()) {
      Get.put<TeacherEvaluationController>(
        TeacherEvaluationController(
          Get.find<TeacherSessionController>(),
          Get.find<TeacherCourseImportController>(),
          Get.find<IEvaluationRepository>(),
          Get.find<TeacherCreateEvaluationUseCase>(),
        ),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TeacherResultsViewMapper>()) {
      Get.put<TeacherResultsViewMapper>(
        const TeacherResultsViewMapper(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<TeacherResultsController>()) {
      Get.put<TeacherResultsController>(
        TeacherResultsController(
          Get.find<IEvaluationRepository>(),
          viewMapper: Get.find<TeacherResultsViewMapper>(),
        ),
        permanent: true,
      );
    }

    final sessionController = Get.find<TeacherSessionController>();
    if (sessionController.isLoggedIn) {
      Get.find<TeacherCourseImportController>().ensureHydrated();
      Get.find<TeacherEvaluationController>().ensureHydrated();
    }
  }
}
