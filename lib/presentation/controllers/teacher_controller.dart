import 'package:get/get.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/presentation/models/csv_import_summary.dart';

class TeacherController extends GetxController {
  final ITeacherAuthRepository _authRepo;
  final IGroupRepository       _groupRepo;
  final IEvaluationRepository  _evalRepo;
  final ICourseRepository      _courseRepo;

  TeacherController(this._authRepo, this._groupRepo, this._evalRepo, this._courseRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final teacher   = Rx<Teacher?>(null);
  final isLoading = false.obs;
  final authError = ''.obs;

  String _friendlyRegisterError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return 'No se pudo completar el registro';
    if (raw.contains('409') || raw.toLowerCase().contains('registrado')) {
      return 'El correo ya esta registrado';
    }
    return raw;
  }

  Teacher get currentTeacher => teacher.value!;
  bool get isLoggedIn => teacher.value != null;

  @override
  void onInit() {
    super.onInit();
    ever(teacher, (t) {
      if (t != null) {
        loadCourses();
        loadCategories();
        loadEvaluations();
      }
    });
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      teacher.value = await _authRepo.getCurrentSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> activateSessionFromLogin() async {
    await checkSession();
  }

  void clearSessionStateForRoleSwitch() {
    teacher.value = null;
    authError.value = '';
    _resetTeacherState();
  }

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final t = await _authRepo.register(name, email, password);
      teacher.value = t;
      Get.offAllNamed('/teacher/dash');
    } catch (e) {
      authError.value = _friendlyRegisterError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    clearSessionStateForRoleSwitch();
    Get.offAllNamed('/login');
  }

  // ── Courses ───────────────────────────────────────────────────────────────
  final courses               = <CourseModel>[].obs;
  final courseLoading         = false.obs;
  final courseCreateLoading   = false.obs;
  final courseCreateError     = ''.obs;
  final courseLoadError       = ''.obs;
  final selectedCourseId      = Rx<int?>(null);
  final selectedCourseName    = ''.obs;
  final categoriesForCourse   = <GroupCategory>[].obs;
  final categoriesForCourseError = ''.obs;

  Future<void> loadCourses() async {
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    courseLoading.value = true;
    courseLoadError.value = '';
    try {
      final all = await _courseRepo.getAll(tid);
      courses.assignAll(all);
    } catch (e) {
      courseLoadError.value = 'Error al cargar cursos: $e';
    } finally {
      courseLoading.value = false;
    }
  }

  Future<bool> createCourse(String name, String code) async {
    if (courseCreateLoading.value) return false;

    courseCreateLoading.value = true;
    courseCreateError.value = '';
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    try {
      final course = await _courseRepo.create(
        name: name,
        code: code,
        teacherId: tid,
      );
      courses.insert(0, course);
      return true;
    } catch (e) {
      courseCreateError.value = 'Error al crear curso: $e';
      return false;
    } finally {
      courseCreateLoading.value = false;
    }
  }

  Future<void> deleteCourse(int courseId) async {
    await _courseRepo.delete(courseId);
    courses.removeWhere((c) => c.id == courseId);
    if (selectedCourseId.value == courseId) {
      selectedCourseId.value   = null;
      selectedCourseName.value = '';
      categoriesForCourse.clear();
    }
  }

  Future<void> loadCategoriesForCourse(int courseId) async {
    selectedCourseId.value = courseId;
    final course = courses.firstWhereOrNull((c) => c.id == courseId);
    selectedCourseName.value = course?.name ?? '';
    categoriesForCourseError.value = '';
    try {
      final cats = await _courseRepo.getCategoriesForCourse(courseId);
      categoriesForCourse.assignAll(cats);
    } catch (e) {
      categoriesForCourse.clear();
      categoriesForCourseError.value = 'Error al cargar categorías del curso: $e';
    }
  }

  // ── Group categories (CSV import) ─────────────────────────────────────────
  final categories    = <GroupCategory>[].obs;
  final importLoading = false.obs;
  final importError   = ''.obs;
  final categoriesLoadError = ''.obs;
  final importProgress = ''.obs;
  final lastImportSummary = Rxn<CsvImportSummary>();

  int get totalGroups =>
      categories.fold(0, (s, c) => s + c.groupCount);

  Future<void> loadCategories() async {
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    categoriesLoadError.value = '';
    try {
      final cats = await _groupRepo.getAll(tid);
      categories.assignAll(cats);
      if (cats.isNotEmpty && selectedCategoryId.value == null) {
        selectedCategoryId.value   = cats.first.id;
        selectedCategoryName.value = cats.first.name;
      }
    } catch (e) {
      categoriesLoadError.value = 'Error al cargar categorías: $e';
    }
  }

  Future<void> importCsv(String csvContent, String categoryName, int courseId) async {
    importLoading.value = true;
    importError.value   = '';
    importProgress.value = 'Preparando importación...';
    lastImportSummary.value = null;
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    try {
      importProgress.value = 'Creando grupos y estudiantes...';
      final cat = await _groupRepo.importCsv(csvContent, categoryName, tid, courseId);
      categories.insert(0, cat);
      selectedCategoryId.value   ??= cat.id;
      if (selectedCategoryId.value == cat.id) {
        selectedCategoryName.value = cat.name;
      }
      lastImportSummary.value = CsvImportSummary(
        categoryName: cat.name,
        groupsCreated: cat.groupCount,
        studentsCreated: cat.studentCount,
        courseId: courseId,
      );
    } catch (e) {
      importError.value = 'Error al importar: $e';
      lastImportSummary.value = null;
    } finally {
      importLoading.value = false;
      importProgress.value = '';
    }
  }

  Future<void> deleteCategory(int id) async {
    await _groupRepo.delete(id);
    categories.removeWhere((c) => c.id == id);
    if (selectedCategoryId.value == id) {
      selectedCategoryId.value   = categories.isNotEmpty ? categories.first.id : null;
      selectedCategoryName.value = categories.isNotEmpty ? categories.first.name : '';
    }
  }

  // ── Evaluations ───────────────────────────────────────────────────────────
  final evaluations  = <Evaluation>[].obs;
  final activeEval   = Rx<Evaluation?>(null);
  final evaluationsLoadError = ''.obs;

  Future<void> loadEvaluations() async {
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    evaluationsLoadError.value = '';
    try {
      final all = await _evalRepo.getAll(tid);
      evaluations.assignAll(all);
      activeEval.value = all.firstWhereOrNull((e) => e.isActive);
    } catch (e) {
      evaluationsLoadError.value = 'Error al cargar evaluaciones: $e';
    }
  }

  // ── New evaluation ────────────────────────────────────────────────────────
  final evalName             = 'Sprint 2 Review'.obs;
  final selectedHours        = 48.obs;
  final selectedVisibility   = 'private'.obs;
  final selectedCategoryId   = Rx<int?>(null);
  final selectedCategoryName = ''.obs;
  final evalError            = ''.obs;

  Future<void> createEvaluation() async {
    if (selectedCourseId.value == null) {
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
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    try {
      final eval = await _evalRepo.create(
        name:       evalName.value,
        categoryId: catId,
        hours:      selectedHours.value,
        visibility: selectedVisibility.value,
        teacherId:  tid,
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
    final tid = int.tryParse(teacher.value?.id ?? '') ?? 0;
    await _evalRepo.rename(evalId, newName, tid);
    final idx = evaluations.indexWhere((e) => e.id == evalId);
    if (idx != -1) {
      final old = evaluations[idx];
      evaluations[idx] = Evaluation(
        id:           old.id,
        name:         newName,
        categoryId:   old.categoryId,
        categoryName: old.categoryName,
        courseName:   old.courseName,
        hours:        old.hours,
        visibility:   old.visibility,
        createdAt:    old.createdAt,
        closesAt:     old.closesAt,
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

  // ── Results ───────────────────────────────────────────────────────────────
  final drill              = Rx<int?>(null);
  final groupResults       = <GroupResult>[].obs;
  final resultsLoading     = false.obs;
  final selectedEval       = Rx<Evaluation?>(null);
  final resultsError       = ''.obs;

  Future<void> loadGroupResults(Evaluation eval) async {
    selectedEval.value  = eval;
    drill.value         = null;
    resultsLoading.value = true;
    resultsError.value = '';
    try {
      final results = await _evalRepo.getGroupResults(eval.id);
      groupResults.assignAll(results);
    } catch (e) {
      groupResults.clear();
      resultsError.value = 'Error al cargar resultados: $e';
    } finally {
      resultsLoading.value = false;
    }
  }

  double get overallAverage {
    if (groupResults.isEmpty) return 0;
    final nonZero = groupResults.where((g) => g.average > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.map((g) => g.average).reduce((a, b) => a + b) /
        nonZero.length;
  }

  void _resetTeacherState() {
    courses.clear();
    categoriesForCourse.clear();
    categories.clear();
    evaluations.clear();
    activeEval.value = null;
    selectedCourseId.value = null;
    selectedCourseName.value = '';
    selectedCategoryId.value = null;
    selectedCategoryName.value = '';
    importError.value = '';
    importProgress.value = '';
    evalError.value = '';
    courseLoadError.value = '';
    categoriesForCourseError.value = '';
    categoriesLoadError.value = '';
    evaluationsLoadError.value = '';
    resultsError.value = '';
    groupResults.clear();
    drill.value = null;
    selectedEval.value = null;
    lastImportSummary.value = null;
  }
}
