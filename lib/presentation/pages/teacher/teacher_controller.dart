import 'package:get/get.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class TeacherController extends GetxController {
  final ITeacherAuthRepository _authRepo;
  final IGroupRepository       _groupRepo;
  final IEvaluationRepository  _evalRepo;

  TeacherController(this._authRepo, this._groupRepo, this._evalRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final teacher   = Rx<Teacher?>(null);
  final isLoading = false.obs;
  final authError = ''.obs;

  Teacher get currentTeacher => teacher.value!;
  bool get isLoggedIn => teacher.value != null;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    loadEvaluations();
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      teacher.value = await _authRepo.getCurrentSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final t = await _authRepo.register(name, email, password);
      teacher.value = t;
      Get.offAllNamed('/teacher/dash');
    } catch (_) {
      authError.value = 'El correo ya está registrado';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    teacher.value = null;
    Get.offAllNamed('/login');
  }

  // ── Group categories (CSV import) ─────────────────────────────────────────
  final categories    = <GroupCategory>[].obs;
  final importLoading = false.obs;
  final importError   = ''.obs;

  int get totalGroups =>
      categories.fold(0, (s, c) => s + c.groupCount);

  Future<void> loadCategories() async {
    try {
      final cats = await _groupRepo.getAll();
      categories.assignAll(cats);
      if (cats.isNotEmpty && selectedCategoryId.value == null) {
        selectedCategoryId.value   = cats.first.id;
        selectedCategoryName.value = cats.first.name;
      }
    } catch (_) {}
  }

  Future<void> importCsv(String csvContent, String categoryName) async {
    importLoading.value = true;
    importError.value   = '';
    try {
      final cat = await _groupRepo.importCsv(csvContent, categoryName);
      categories.insert(0, cat);
      selectedCategoryId.value   ??= cat.id;
      if (selectedCategoryId.value == cat.id) {
        selectedCategoryName.value = cat.name;
      }
    } catch (e) {
      importError.value = 'Error al importar: $e';
    } finally {
      importLoading.value = false;
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

  Future<void> loadEvaluations() async {
    try {
      final all = await _evalRepo.getAll();
      evaluations.assignAll(all);
      activeEval.value = all.firstWhereOrNull((e) => e.isActive);
    } catch (_) {}
  }

  // ── New evaluation ────────────────────────────────────────────────────────
  final evalName             = 'Sprint 2 Review'.obs;
  final selectedHours        = 48.obs;
  final selectedVisibility   = 'private'.obs;
  final selectedCategoryId   = Rx<int?>(null);
  final selectedCategoryName = ''.obs;
  final evalError            = ''.obs;

  Future<void> createEvaluation() async {
    final catId = selectedCategoryId.value;
    if (catId == null) {
      evalError.value = 'Selecciona una categoría de grupos';
      return;
    }
    isLoading.value = true;
    evalError.value = '';
    try {
      final eval = await _evalRepo.create(
        name:       evalName.value,
        categoryId: catId,
        hours:      selectedHours.value,
        visibility: selectedVisibility.value,
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

  // ── Results ───────────────────────────────────────────────────────────────
  final drill              = Rx<int?>(null);
  final groupResults       = <GroupResult>[].obs;
  final resultsLoading     = false.obs;
  final selectedEval       = Rx<Evaluation?>(null);

  Future<void> loadGroupResults(Evaluation eval) async {
    selectedEval.value  = eval;
    drill.value         = null;
    resultsLoading.value = true;
    try {
      final results = await _evalRepo.getGroupResults(eval.id);
      groupResults.assignAll(results);
    } catch (_) {
      groupResults.clear();
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

  static const List<String> criteriaLabels = [
    'PUNTU', 'CONTRIB', 'COMPRO', 'ACTITU',
  ];
  static const List<double> criteriaColors = [
    0xFF60A5FA, 0xFFA78BFA, 0xFF34D399, 0xFFF9A8D4,
  ];
}
