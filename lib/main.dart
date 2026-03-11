import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/repositories/teacher_auth_repository_impl.dart';
import 'package:example/data/services/database_service.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/presentation/theme/app_colors.dart';

// Student
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/presentation/pages/student/s_login_page.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';
import 'package:example/presentation/pages/student/s_eval_list_page.dart';
import 'package:example/presentation/pages/student/s_peer_score_page.dart';
import 'package:example/presentation/pages/student/s_my_results_page.dart';
import 'package:example/presentation/pages/auth/s_register_page.dart';

// Teacher
import 'package:example/presentation/pages/teacher/teacher_controller.dart';
import 'package:example/presentation/pages/teacher/t_login_page.dart';
import 'package:example/presentation/pages/teacher/t_register_page.dart';
import 'package:example/presentation/pages/teacher/t_dash_page.dart';
import 'package:example/presentation/pages/teacher/t_import_page.dart';
import 'package:example/presentation/pages/teacher/t_new_eval_page.dart';
import 'package:example/presentation/pages/teacher/t_results_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PeerEvalApp());
}

// ── Bindings ──────────────────────────────────────────────────────────────────

class _AppBindings extends Bindings {
  @override
  void dependencies() {
    final db = DatabaseService();
    Get.put(db, permanent: true);
    Get.put<IAuthRepository>(AuthRepositoryImpl(db), permanent: true);
    Get.put<ITeacherAuthRepository>(
        TeacherAuthRepositoryImpl(db), permanent: true);
    Get.put(StudentController(Get.find<IAuthRepository>()), permanent: true);
    Get.put(TeacherController(Get.find<ITeacherAuthRepository>()),
        permanent: true);
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

class PeerEvalApp extends StatelessWidget {
  const PeerEvalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Evalia',
      debugShowCheckedModeBanner: false,
      initialBinding: _AppBindings(),
      theme: ThemeData(
        scaffoldBackgroundColor: skBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: skPrimary),
      ),
      home: const _SplashPage(),
      getPages: [
        // Student
        GetPage(name: '/student/login',     page: () => const SLoginPage()),
        GetPage(name: '/student/register',  page: () => const SRegisterPage()),
        GetPage(name: '/student/courses',   page: () => const SCoursesPage()),
        GetPage(name: '/student/eval-list', page: () => const SEvalListPage()),
        GetPage(name: '/student/peer-score',page: () => const SPeerScorePage()),
        GetPage(name: '/student/results',   page: () => const SMyResultsPage()),
        // Teacher
        GetPage(name: '/teacher/login',    page: () => const TLoginPage()),
        GetPage(name: '/teacher/register', page: () => const TRegisterPage()),
        GetPage(name: '/teacher/dash',     page: () => const TDashPage()),
        GetPage(name: '/teacher/import',   page: () => const TImportPage()),
        GetPage(name: '/teacher/new-eval', page: () => const TNewEvalPage()),
        GetPage(name: '/teacher/results',  page: () => const TResultsPage()),
      ],
    );
  }
}

// ── Splash ────────────────────────────────────────────────────────────────────

class _SplashPage extends StatefulWidget {
  const _SplashPage();

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final student = Get.find<StudentController>();
    final teacher = Get.find<TeacherController>();

    await Future.wait([
      student.checkSession(),
      teacher.checkSession(),
    ]);

    if (teacher.isLoggedIn) {
      Get.offAllNamed('/teacher/dash');
    } else if (student.isLoggedIn) {
      Get.offAllNamed('/student/courses');
    } else {
      Get.offAllNamed('/student/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: skBackground,
      body: Center(
        child: CircularProgressIndicator(color: skPrimary, strokeWidth: 2),
      ),
    );
  }
}
