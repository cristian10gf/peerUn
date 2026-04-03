import 'package:get/get.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

class TeacherEvaluationController extends GetxController {
  final TeacherSessionController _sessionController;
  final TeacherCourseImportController _courseImportController;
  final IEvaluationRepository _evalRepo;
  final TeacherCreateEvaluationUseCase _teacherCreateEvaluationUseCase;

  TeacherEvaluationController(
    this._sessionController,
    this._courseImportController,
    this._evalRepo,
    this._teacherCreateEvaluationUseCase,
  );

  final evaluations = <Evaluation>[].obs;
  final activeEval = Rx<Evaluation?>(null);
  final evaluationsLoadError = ''.obs;

  final isLoading = false.obs;
  final evalName = 'Sprint 2 Review'.obs;
  final selectedHours = 48.obs;
  final selectedVisibility = 'private'.obs;
  final selectedCategoryId = Rx<int?>(null);
  final selectedCategoryName = ''.obs;
  final evalError = ''.obs;
  final _hasHydrated = false.obs;

  late final Worker _sessionWorker;

  int get _teacherId => int.tryParse(_sessionController.teacher.value?.id ?? '') ?? 0;

  @override
  void onInit() {
    super.onInit();
    _sessionWorker = ever(_sessionController.teacher, (t) {
      if (t != null) {
        ensureHydrated(forceRefresh: true);
      } else {
        resetState();
      }
    });

    if (_sessionController.teacher.value != null) {
      ensureHydrated();
    }
  }

  @override
  void onClose() {
    _sessionWorker.dispose();
    super.onClose();
  }

  Future<void> loadEvaluations() async {
    evaluationsLoadError.value = '';
    try {
      final all = await _evalRepo.getAll(_teacherId);
      evaluations.assignAll(all);
      activeEval.value = all.firstWhereOrNull((e) => e.isActive);
    } catch (e) {
      evaluationsLoadError.value = 'Error al cargar evaluaciones: $e';
    }
  }

  Future<void> ensureHydrated({bool forceRefresh = false}) async {
    if (_teacherId == 0) return;
    if (!forceRefresh && _hasHydrated.value) return;

    await loadEvaluations();
    _hasHydrated.value = true;
  }

  void setEvalName(String value) {
    evalName.value = value;
  }

  void setSelectedHours(int hours) {
    selectedHours.value = hours;
  }

  void setSelectedVisibility(String visibility) {
    selectedVisibility.value = visibility;
  }

  Future<void> selectCourseForEvaluation(int courseId) async {
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    await _courseImportController.loadCategoriesForCourse(courseId);
  }

  void selectCategoryForEvaluation(int categoryId, String categoryName) {
    selectedCategoryId.value = categoryId;
    selectedCategoryName.value = categoryName;
  }

  Future<void> createEvaluation() async {
    if (_courseImportController.selectedCourseId.value == null) {
      evalError.value = 'Selecciona un curso';
      return;
    }

    final catId = selectedCategoryId.value;
    if (catId == null) {
      evalError.value = 'Selecciona una categoría de grupos';
      return;
    }

    isLoading.value = true;
    evalError.value = '';
    try {
      final eval = await _teacherCreateEvaluationUseCase.execute(
        TeacherCreateEvaluationInput(
          name: evalName.value,
          categoryId: catId,
          hours: selectedHours.value,
          visibility: selectedVisibility.value,
          teacherId: _teacherId,
        ),
      );
      evaluations.insert(0, eval);
      activeEval.value = eval.isActive ? eval : activeEval.value;
      Get.offAllNamed('/teacher/dash');
      Get.snackbar(
        'Evaluación lanzada',
        '${eval.name} está activa por ${eval.hours}h',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      evalError.value = 'Error al crear evaluación: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renameEvaluation(int evalId, String newName) async {
    await _evalRepo.rename(evalId, newName, _teacherId);
    final idx = evaluations.indexWhere((e) => e.id == evalId);
    if (idx != -1) {
      final old = evaluations[idx];
      evaluations[idx] = Evaluation(
        id: old.id,
        name: newName,
        categoryId: old.categoryId,
        categoryName: old.categoryName,
        courseName: old.courseName,
        hours: old.hours,
        visibility: old.visibility,
        createdAt: old.createdAt,
        closesAt: old.closesAt,
      );
      if (activeEval.value?.id == evalId) {
        activeEval.value = evaluations[idx];
      }
    }
  }

  Future<void> deleteEvaluation(int evalId) async {
    await _evalRepo.delete(evalId);
    evaluations.removeWhere((e) => e.id == evalId);
    if (activeEval.value?.id == evalId) {
      activeEval.value = evaluations.firstWhereOrNull((e) => e.isActive);
    }
  }

  void resetState() {
    evaluations.clear();
    activeEval.value = null;
    evaluationsLoadError.value = '';

    isLoading.value = false;
    evalName.value = 'Sprint 2 Review';
    selectedHours.value = 48;
    selectedVisibility.value = 'private';
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    evalError.value = '';
    _hasHydrated.value = false;
  }
}
