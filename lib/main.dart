import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/services/database_service.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/presentation/pages/student/s_login_page.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';
import 'package:example/presentation/pages/student/s_eval_list_page.dart';
import 'package:example/presentation/pages/student/s_peer_score_page.dart';
import 'package:example/presentation/pages/student/s_my_results_page.dart';
import 'package:example/presentation/pages/auth/s_register_page.dart';

void main() {
  runApp(const PeerEvalApp());
}

// ── Bindings ─────────────────────────────────────────────────────────────────

class _AppBindings extends Bindings {
  @override
  void dependencies() {
    final db = DatabaseService();
    Get.put(db, permanent: true);
    Get.put<IAuthRepository>(AuthRepositoryImpl(db), permanent: true);
    Get.put(StudentController(Get.find<IAuthRepository>()), permanent: true);
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

class PeerEvalApp extends StatelessWidget {
  const PeerEvalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PeerEval',
      debugShowCheckedModeBanner: false,
      initialBinding: _AppBindings(),
      theme: ThemeData(
        scaffoldBackgroundColor: skBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: skPrimary),
      ),
      home: const _SplashPage(),
      getPages: [
        GetPage(name: '/student/login',     page: () => const SLoginPage()),
        GetPage(name: '/student/register',  page: () => const SRegisterPage()),
        GetPage(name: '/student/courses',   page: () => const SCoursesPage()),
        GetPage(name: '/student/eval-list', page: () => const SEvalListPage()),
        GetPage(name: '/student/peer-score',page: () => const SPeerScorePage()),
        GetPage(name: '/student/results',   page: () => const SMyResultsPage()),
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
    final ctrl = Get.find<StudentController>();
    await ctrl.checkSession();
    if (ctrl.isLoggedIn) {
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
        child: CircularProgressIndicator(
          color: skPrimary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
