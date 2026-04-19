import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/models/csv_import_summary.dart';

class TeacherCourseImportController extends GetxController {
  final TeacherSessionController _sessionController;
  final IGroupRepository _groupRepo;
  final ICourseRepository _courseRepo;
  final TeacherImportCsvUseCase _teacherImportCsvUseCase;

  TeacherCourseImportController(
    this._sessionController,
    this._groupRepo,
    this._courseRepo,
    this._teacherImportCsvUseCase,
  );

  final courses = <CourseModel>[].obs;
  final courseLoading = false.obs;
  final courseCreateLoading = false.obs;
  final courseCreateError = ''.obs;
  final courseLoadError = ''.obs;
  final selectedCourseId = Rx<int?>(null);
  final selectedCourseName = ''.obs;
  final categoriesForCourse = <GroupCategory>[].obs;
  final categoriesForCourseError = ''.obs;

  final categories = <GroupCategory>[].obs;
  final importLoading = false.obs;
  final importError = ''.obs;
  final categoriesLoadError = ''.obs;
  final importProgress = ''.obs;
  final lastImportSummary = Rxn<CsvImportSummary>();
  final _hasHydrated = false.obs;

  late final Worker _sessionWorker;

  int get totalGroups => categories.fold(0, (s, c) => s + c.groupCount);

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

  Future<void> loadCourses() async {
    courseLoading.value = true;
    courseLoadError.value = '';
    try {
      final all = await _courseRepo.getAll(_teacherId);
      courses.assignAll(all);
    } catch (e) {
      courseLoadError.value = parseApiError(e, fallback: 'Error al cargar cursos');
    } finally {
      courseLoading.value = false;
    }
  }

  Future<void> ensureHydrated({bool forceRefresh = false}) async {
    if (_teacherId == 0) return;
    if (!forceRefresh && _hasHydrated.value) return;

    await Future.wait([
      loadCourses(),
      loadCategories(),
    ]);

    _hasHydrated.value = true;
  }

  Future<bool> createCourse(String name, String code) async {
    if (courseCreateLoading.value) return false;

    courseCreateLoading.value = true;
    courseCreateError.value = '';
    try {
      final course = await _courseRepo.create(
        name: name,
        code: code,
        teacherId: _teacherId,
      );
      courses.insert(0, course);
      return true;
    } catch (e) {
      courseCreateError.value = parseApiError(e, fallback: 'Error al crear curso');
      return false;
    } finally {
      courseCreateLoading.value = false;
    }
  }

  Future<void> deleteCourse(int courseId) async {
    await _courseRepo.delete(courseId);
    courses.removeWhere((c) => c.id == courseId);
    if (selectedCourseId.value == courseId) {
      selectedCourseId.value = null;
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
      categoriesForCourseError.value = parseApiError(e, fallback: 'Error al cargar categorías del curso');
    }
  }

  Future<void> loadCategories() async {
    categoriesLoadError.value = '';
    try {
      final cats = await _groupRepo.getAll(_teacherId);
      categories.assignAll(cats);
    } catch (e) {
      categoriesLoadError.value = parseApiError(e, fallback: 'Error al cargar categorías');
    }
  }

  Future<void> importCsv(String csvContent, String categoryName, int courseId) async {
    await importCsvFromFilename(csvContent, '$categoryName.csv', courseId);
  }

  Future<void> importCsvFromFilename(String csvContent, String fileName, int courseId) async {
    importLoading.value = true;
    importError.value = '';
    importProgress.value = 'Preparando importación...';
    lastImportSummary.value = null;
    try {
      importProgress.value = 'Creando grupos y estudiantes...';
      final imported = await _teacherImportCsvUseCase.execute(
        csvContent: csvContent,
        fileName: fileName,
        teacherId: _teacherId,
        courseId: courseId,
      );

      final cat = imported.category;
      categories.insert(0, cat);
      lastImportSummary.value = CsvImportSummary(
        categoryName: imported.categoryName,
        groupsCreated: imported.groupsCreated,
        studentsCreated: imported.studentsCreated,
        courseId: imported.courseId,
      );
    } catch (e) {
      importError.value = parseApiError(e, fallback: 'Error al importar CSV');
      lastImportSummary.value = null;
    } finally {
      importLoading.value = false;
      importProgress.value = '';
    }
  }

  Future<void> deleteCategory(int id) async {
    await _groupRepo.delete(id);
    categories.removeWhere((c) => c.id == id);
    categoriesForCourse.removeWhere((c) => c.id == id);
  }

  void resetState() {
    courses.clear();
    courseLoading.value = false;
    courseCreateLoading.value = false;
    courseCreateError.value = '';
    courseLoadError.value = '';
    selectedCourseId.value = null;
    selectedCourseName.value = '';
    categoriesForCourse.clear();
    categoriesForCourseError.value = '';

    categories.clear();
    importLoading.value = false;
    importError.value = '';
    categoriesLoadError.value = '';
    importProgress.value = '';
    lastImportSummary.value = null;
    _hasHydrated.value = false;
  }
}
