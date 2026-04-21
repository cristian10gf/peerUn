import 'package:example/presentation/pages/auth/inicio_newUI.dart';
import 'package:example/presentation/pages/auth/login_newUI.dart';
import 'package:example/presentation/pages/auth/register_newUI.dart';
import 'package:example/presentation/pages/student/student_course_page_newUI.dart';
import 'package:example/presentation/pages/student/student_home_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_course_page_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_create_category_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_create_course_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_create_eval_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_criteria_page_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_edit_category_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_edit_criteria_page.dart';
import 'package:example/presentation/pages/teacher/teacher_home_newUI.dart';
import 'package:example/presentation/pages/teacher/teacher_reports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'package:example/data/repositories/auth_repository_impl.dart';
import 'package:example/data/repositories/teacher_auth_repository_impl.dart';
import 'package:example/data/repositories/group_repository_impl.dart';
import 'package:example/data/repositories/evaluation_repository_impl.dart';
import 'package:example/data/repositories/course_repository_impl.dart';
import 'package:example/data/repositories/connectivity_repository_impl.dart';
import 'package:example/data/repositories/unified_auth_repository_impl.dart';
import 'package:example/data/services/connectivity_service.dart';
import 'package:example/data/services/database/database_service.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_connectivity_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';
import 'package:example/domain/services/i_cache_service.dart';
import 'package:example/data/services/cache/shared_prefs_cache_service.dart';
import 'package:example/domain/use_case/teacher/teacher_import_csv_use_case.dart';
import 'package:example/domain/use_case/teacher/teacher_create_evaluation_use_case.dart';
import 'package:example/presentation/bindings/teacher_module_binding.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:example/presentation/theme/app_colors.dart';
//import 'package:example/presentation/theme/teacher_colors.dart';

// Student
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';
import 'package:example/presentation/pages/student/s_eval_list_page.dart';
import 'package:example/presentation/pages/student/s_peer_score_page.dart';
import 'package:example/presentation/pages/student/s_my_results_page.dart';
import 'package:example/presentation/pages/student/s_peers_page.dart';
import 'package:example/presentation/pages/student/s_profile_page.dart';
import 'package:example/presentation/pages/auth/register_page.dart';
import 'package:example/presentation/pages/auth/login_page.dart';
import 'package:example/presentation/controllers/login_controller.dart';

// Teacher
import 'package:example/presentation/pages/teacher/t_dash_page.dart';
import 'package:example/presentation/pages/teacher/t_import_page.dart';
import 'package:example/presentation/pages/teacher/t_new_eval_page.dart';
import 'package:example/presentation/pages/teacher/t_data_insights_page.dart';
import 'package:example/presentation/pages/teacher/t_results_page.dart';
import 'package:example/presentation/pages/teacher/t_profile_page.dart';
import 'package:example/presentation/pages/teacher/t_course_manage_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {
    // Optional in local/dev. Fallback values are handled in app getters.
  }
  runApp(const PeerEvalApp());
}

// ── Bindings ──────────────────────────────────────────────────────────────────

class _AppBindings extends Bindings {
  @override
  void dependencies() {
    final db = DatabaseService();
    final connectivityService = ConnectivityService();

    Get.put(db, permanent: true);
    Get.put(connectivityService, permanent: true);
    Get.put<IConnectivityRepository>(
      ConnectivityRepositoryImpl(connectivityService),
      permanent: true,
    );
    Get.put(
      ConnectivityController(Get.find<IConnectivityRepository>()),
      permanent: true,
    );

    // ── Cache ── registered before any controller that depends on it ──────────
    Get.put<ICacheService>(SharedPreferencesCacheService(), permanent: true);
    // ─────────────────────────────────────────────────────────────────────────

    Get.put<IAuthRepository>(AuthRepositoryImpl(db), permanent: true);
    Get.put<ITeacherAuthRepository>(
      TeacherAuthRepositoryImpl(db),
      permanent: true,
    );
    Get.put<IGroupRepository>(GroupRepositoryImpl(db), permanent: true);
    Get.put<IEvaluationRepository>(
      EvaluationRepositoryImpl(db),
      permanent: true,
    );
    Get.put<ICourseRepository>(CourseRepositoryImpl(db), permanent: true);
    Get.put(
      TeacherImportCsvUseCase(Get.find<IGroupRepository>()),
      permanent: true,
    );
    Get.put(
      TeacherCreateEvaluationUseCase(Get.find<IEvaluationRepository>()),
      permanent: true,
    );
    Get.put(
      StudentController(
        Get.find<IAuthRepository>(),
        Get.find<IEvaluationRepository>(),
        Get.find<ICacheService>(),
      ),
      permanent: true,
    );
    Get.put(
      TeacherSessionController(Get.find<ITeacherAuthRepository>()),
      permanent: true,
    );
    Get.put<IUnifiedAuthRepository>(
      UnifiedAuthRepositoryImpl(db),
      permanent: true,
    );
    Get.put(
      LoginController(
        Get.find<IUnifiedAuthRepository>(),
        Get.find<StudentController>(),
        Get.find<TeacherSessionController>(),
      ),
      permanent: true,
    );
    Get.put<TeacherInsightsDomainService>(
      const TeacherInsightsDomainService(),
      permanent: true,
    );
    Get.put<TeacherInsightsViewMapper>(
      const TeacherInsightsViewMapper(),
      permanent: true,
    );
    Get.put(
      TeacherInsightsController(
        Get.find<IEvaluationRepository>(),
        Get.find<TeacherInsightsDomainService>(),
        Get.find<TeacherInsightsViewMapper>(),
        Get.find<TeacherSessionController>(),
        Get.find<ICacheService>(),
      ),
      permanent: true,
    );
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

class PeerEvalApp extends StatelessWidget {
  const PeerEvalApp({super.key});

  String get _appName {
    final fromEnv = dotenv.isInitialized
        ? dotenv.env['APP_NAME']?.trim()
        : null;
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'Evalia';
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: _appName,
      debugShowCheckedModeBanner: false,
      initialBinding: _AppBindings(),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: skBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: skPrimary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: tkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: tkGold,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const _SplashPage(),
      getPages: [
        // Unified auth
        GetPage(name: '/inicio_newUI', page: () => const InicioNewUI()),
        GetPage(name: '/login_newUI', page: () => const LoginNewUI()),
        GetPage(name: '/register_newUI', page: () => const RegisterNewUI()),
        // Student
        GetPage(name: '/student/courses', page: () => const StudentHomeNewUI()),
        GetPage(name: '/student/course', page:() => const StudentCoursePage()),
        GetPage(name: '/student/eval-list', page: () => const SEvalListPage()),
        GetPage(
          name: '/student/peer-score',
          page: () => const SPeerScorePage(),
        ),
        GetPage(name: '/student/peers', page: () => const SPeersPage()),
        GetPage(name: '/student/results', page: () => const SMyResultsPage()),
        GetPage(name: '/student/profile', page: () => const SProfilePage()),

        // Teacher
        GetPage(
          name: '/teacher/dash',
          page: () => const TeacherHomeNewUI(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/import',
          page: () => const TImportPage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/new-eval',
          page: () => const TeacherCreateEvalNewUI(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/results',
          page: () => const TeacherReportsUI(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/eval-results',
          page: () => TResultsPage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/data-insights',
          page: () => const TDataInsightsPage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/profile',
          page: () => const TProfilePage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/courses',
          page: () => const TCourseManagePage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/course',
          page: () => const TeacherCoursePage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/new-category',
          page: () => const TeacherCreateCategoryPage(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/edit-category',
          page: () => const TeacherEditCategoryNewUI(),
        ),
        GetPage(
          name: '/teacher/new-course',
          page: () => const TeacherCreateCourseNewUI(),
          binding: TeacherModuleBinding(),
        ),
        GetPage(
          name: '/teacher/criteria',
          page: () => const TeacherCriteriaPage(),
        ),

        GetPage(
          name: '/teacher/edit-criteria',
          page: () => const TeacherEditCriteriaPage(),
        ),

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
    final teacher = Get.find<TeacherSessionController>();

    try {
      await Future.wait([
        student.checkSession(),
        teacher.checkSession(),
      ]).timeout(const Duration(seconds: 8));
    } catch (_) {
      // timeout or error — fall through to login
    }

    if (!mounted) return;

    if (teacher.isLoggedIn) {
      Get.offAllNamed('/teacher/dash');
    } else if (student.isLoggedIn) {
      Get.offAllNamed('/student/courses');
    } else {
      Get.offAllNamed('/inicio_newUI');
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
