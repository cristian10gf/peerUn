import 'package:get/get.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';

class LoginController extends GetxController {
  final IUnifiedAuthRepository _authRepo;
  final StudentController _studentController;
  final TeacherController _teacherController;

  LoginController(
    this._authRepo,
    this._studentController,
    this._teacherController,
  );

  final isLoading = false.obs;
  final authError = ''.obs;

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
        await _teacherController.checkSession();
        _studentController.student.value = null;
      } else {
        await _studentController.checkSession();
        _teacherController.teacher.value = null;
      }

      Get.offAllNamed(result.homeRoute);
    } catch (_) {
      authError.value = 'Error al conectar con la base de datos';
    } finally {
      isLoading.value = false;
    }
  }

  void clearError() => authError.value = '';
}
