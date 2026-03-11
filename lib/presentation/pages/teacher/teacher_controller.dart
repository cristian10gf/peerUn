import 'package:get/get.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherController extends GetxController {
  final ITeacherAuthRepository _authRepo;
  TeacherController(this._authRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final teacher = Rx<Teacher?>(null);
  final isLoading = false.obs;
  final authError = ''.obs;

  Teacher get currentTeacher => teacher.value!;
  bool get isLoggedIn => teacher.value != null;

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

  // ── Dashboard mock data ───────────────────────────────────────────────────
  final courses = <TeacherCourse>[
    const TeacherCourse(
      id: 'c1',
      name: 'Desarrollo Móvil 2026-10',
      code: 'DM2610',
      groupCount: 8,
      hasActive: true,
    ),
    const TeacherCourse(
      id: 'c2',
      name: 'Arquitectura de Software',
      code: 'AS2610',
      groupCount: 12,
    ),
  ];

  // ── Import groups ─────────────────────────────────────────────────────────
  final importCategories = <ImportCategory>[
    ImportCategory(
      name: 'Equipos Sprint 1',
      groupCount: 8,
      studentCount: 32,
      lastSync: 'Ayer',
      syncOk: true,
    ),
    ImportCategory(
      name: 'Equipos Proyecto Final',
      groupCount: 10,
      studentCount: 40,
      lastSync: 'Nunca',
      syncOk: false,
    ),
    ImportCategory(
      name: 'Grupos de Estudio',
      groupCount: 4,
      studentCount: 16,
      lastSync: 'Hace 5 días',
      syncOk: true,
    ),
  ].obs;

  int get selectedCategoryCount =>
      importCategories.where((c) => c.selected).length;

  void toggleCategory(int index) {
    importCategories[index].selected = !importCategories[index].selected;
    importCategories.refresh();
  }

  // ── New evaluation ────────────────────────────────────────────────────────
  final evalName = 'Sprint 2 Review'.obs;
  final selectedHours = 48.obs;
  final selectedVisibility = 'private'.obs;

  // ── Results ───────────────────────────────────────────────────────────────
  final drill = Rx<int?>(null);

  final groups = <GroupResult>[
    GroupResult(
      name: 'Equipo Ágil 1',
      average: 4.2,
      criteria: [4.0, 4.5, 4.1, 4.2],
      students: [
        StudentResult(
          initial: 'M',
          name: 'M. García',
          score: 4.5,
          avatarColor: tkBlue,
        ),
        StudentResult(
          initial: 'C',
          name: 'C. López',
          score: 3.8,
          avatarColor: tkPurple,
        ),
        StudentResult(
          initial: 'J',
          name: 'J. Martínez',
          score: 4.2,
          avatarColor: tkSuccess,
        ),
        StudentResult(
          initial: 'A',
          name: 'A. Torres',
          score: 4.0,
          avatarColor: tkPink,
        ),
      ],
    ),
    GroupResult(
      name: 'Equipo Ágil 2',
      average: 3.6,
      criteria: [3.5, 3.8, 3.4, 3.7],
      students: [
        StudentResult(
          initial: 'L',
          name: 'L. Ramírez',
          score: 3.5,
          avatarColor: tkBlue,
        ),
        StudentResult(
          initial: 'S',
          name: 'S. Herrera',
          score: 3.8,
          avatarColor: tkPurple,
        ),
        StudentResult(
          initial: 'D',
          name: 'D. Castro',
          score: 3.4,
          avatarColor: tkSuccess,
        ),
        StudentResult(
          initial: 'P',
          name: 'P. Gómez',
          score: 3.7,
          avatarColor: tkPink,
        ),
      ],
    ),
    GroupResult(
      name: 'Equipo Ágil 3',
      average: 4.7,
      criteria: [4.8, 4.6, 4.7, 4.7],
      students: [
        StudentResult(
          initial: 'R',
          name: 'R. Vargas',
          score: 4.8,
          avatarColor: tkBlue,
        ),
        StudentResult(
          initial: 'N',
          name: 'N. Peña',
          score: 4.6,
          avatarColor: tkPurple,
        ),
        StudentResult(
          initial: 'F',
          name: 'F. Morales',
          score: 4.7,
          avatarColor: tkSuccess,
        ),
        StudentResult(
          initial: 'V',
          name: 'V. Ríos',
          score: 4.7,
          avatarColor: tkPink,
        ),
      ],
    ),
  ];

  double get overallAverage {
    if (groups.isEmpty) return 0;
    return groups.map((g) => g.average).reduce((a, b) => a + b) / groups.length;
  }

  static const List<String> criteriaLabels = [
    'PUNTU',
    'CONTRIB',
    'COMPRO',
    'ACTITU',
  ];
  static const List<double> criteriaColors = [
    0xFF60A5FA,
    0xFFA78BFA,
    0xFF34D399,
    0xFFF9A8D4,
  ];
}
