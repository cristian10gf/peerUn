import 'package:get/get.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';

class TeacherController extends GetxController {
  final ITeacherAuthRepository _authRepo;
  final IGroupRepository       _groupRepo;

  TeacherController(this._authRepo, this._groupRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final teacher   = Rx<Teacher?>(null);
  final isLoading = false.obs;
  final authError = ''.obs;

  Teacher get currentTeacher => teacher.value!;
  bool    get isLoggedIn     => teacher.value != null;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      teacher.value = await _authRepo.getCurrentSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      authError.value = 'Completa todos los campos';
      return;
    }
    isLoading.value = true;
    authError.value = '';
    try {
      final t = await _authRepo.login(email, password);
      if (t == null) {
        authError.value = 'Correo o contraseña incorrectos';
      } else {
        teacher.value = t;
        Get.offAllNamed('/teacher/dash');
      }
    } catch (_) {
      authError.value = 'Error al conectar con la base de datos';
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
    Get.offAllNamed('/teacher/login');
  }

  // ── Dashboard mock data ───────────────────────────────────────────────────
  final courses = <TeacherCourse>[
    const TeacherCourse(
      id: 'c1', name: 'Desarrollo Móvil 2026-10',
      code: 'DM2610', groupCount: 8, hasActive: true,
    ),
    const TeacherCourse(
      id: 'c2', name: 'Arquitectura de Software',
      code: 'AS2610', groupCount: 12,
    ),
  ];

  // ── Group categories (CSV import) ─────────────────────────────────────────
  final categories   = <GroupCategory>[].obs;
  final importLoading = false.obs;
  final importError   = ''.obs;

  Future<void> loadCategories() async {
    try {
      categories.assignAll(await _groupRepo.getAll());
    } catch (_) {
      // ignore on startup
    }
  }

  Future<void> importCsv(String csvContent, String categoryName) async {
    importLoading.value = true;
    importError.value   = '';
    try {
      final cat = await _groupRepo.importCsv(csvContent, categoryName);
      categories.insert(0, cat);
    } catch (e) {
      importError.value = 'Error al importar: $e';
    } finally {
      importLoading.value = false;
    }
  }

  Future<void> deleteCategory(int id) async {
    await _groupRepo.delete(id);
    categories.removeWhere((c) => c.id == id);
  }

  // ── New evaluation ────────────────────────────────────────────────────────
  final evalName           = 'Sprint 2 Review'.obs;
  final selectedHours      = 48.obs;
  final selectedVisibility = 'private'.obs;

  // ── Results ───────────────────────────────────────────────────────────────
  final drill = Rx<int?>(null);

  final groups = <GroupResult>[
    GroupResult(
      name: 'Equipo Ágil 1', average: 4.2,
      criteria: [4.0, 4.5, 4.1, 4.2],
      students: [
        StudentResult(initial: 'M', name: 'M. García',   score: 4.5),
        StudentResult(initial: 'C', name: 'C. López',    score: 3.8),
        StudentResult(initial: 'J', name: 'J. Martínez', score: 4.2),
        StudentResult(initial: 'A', name: 'A. Torres',   score: 4.0),
      ],
    ),
    GroupResult(
      name: 'Equipo Ágil 2', average: 3.6,
      criteria: [3.5, 3.8, 3.4, 3.7],
      students: [
        StudentResult(initial: 'L', name: 'L. Ramírez',  score: 3.5),
        StudentResult(initial: 'S', name: 'S. Herrera',  score: 3.8),
        StudentResult(initial: 'D', name: 'D. Castro',   score: 3.4),
        StudentResult(initial: 'P', name: 'P. Gómez',    score: 3.7),
      ],
    ),
    GroupResult(
      name: 'Equipo Ágil 3', average: 4.7,
      criteria: [4.8, 4.6, 4.7, 4.7],
      students: [
        StudentResult(initial: 'R', name: 'R. Vargas',   score: 4.8),
        StudentResult(initial: 'N', name: 'N. Peña',     score: 4.6),
        StudentResult(initial: 'F', name: 'F. Morales',  score: 4.7),
        StudentResult(initial: 'V', name: 'V. Ríos',     score: 4.7),
      ],
    ),
  ];

  double get overallAverage {
    if (groups.isEmpty) return 0;
    return groups.map((g) => g.average).reduce((a, b) => a + b) / groups.length;
  }

  static const List<String> criteriaLabels = [
    'PUNTU', 'CONTRIB', 'COMPRO', 'ACTITU',
  ];
  static const List<double> criteriaColors = [
    0xFF60A5FA, 0xFFA78BFA, 0xFF34D399, 0xFFF9A8D4,
  ];
}
