import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';

class TeacherSessionController extends GetxController {
  final ITeacherAuthRepository _authRepo;

  TeacherSessionController(this._authRepo);

  final teacher = Rx<Teacher?>(null);
  final isLoading = false.obs;
  final authError = ''.obs;

  Teacher get currentTeacher => teacher.value!;
  bool get isLoggedIn => teacher.value != null;

  String _friendlyRegisterError(Object error) =>
      parseApiErrorFriendly(
        error,
        fallback: 'No se pudo completar el registro',
        overrides: const {'409': 'El correo ya está registrado'},
      );

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
}
