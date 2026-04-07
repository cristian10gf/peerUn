import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

class LoginController extends GetxController {
  final IUnifiedAuthRepository _authRepo;
  final StudentController _studentController;
  final TeacherSessionController _teacherController;

  LoginController(
    this._authRepo,
    this._studentController,
    this._teacherController,
  );

  final isLoading = false.obs;
  final authError = ''.obs;

  String _friendlyError(Object error) =>
      parseApiErrorFriendly(error, fallback: 'Error al iniciar sesión');

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      authError.value = 'Completa todos los campos';
      return;
    }

    isLoading.value = true;
    authError.value = '';

    try {
      final result = await _authRepo.loginAndResolve(email, password);

      if (result == null) {
        authError.value = 'Correo o contraseña incorrectos';
        return;
      }

      if (result.role == AppUserRole.teacher) {
        _studentController.clearSessionStateForRoleSwitch();
        await _teacherController.activateSessionFromLogin();
      } else {
        _teacherController.clearSessionStateForRoleSwitch();
        await _studentController.activateSessionFromLogin();
      }

      Get.offAllNamed(result.homeRoute);
    } catch (e) {
      authError.value = _friendlyError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() => authError.value = '';
}
