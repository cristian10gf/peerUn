import 'package:get/get.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';

class StudentController extends GetxController {
  final IAuthRepository _authRepo;
  StudentController(this._authRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final student    = Rx<Student?>(null);
  final isLoading  = false.obs;
  final authError  = ''.obs;

  Student get currentStudent => student.value!;
  bool    get isLoggedIn     => student.value != null;

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      student.value = await _authRepo.getCurrentSession();
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
      final s = await _authRepo.login(email, password);
      if (s == null) {
        authError.value = 'Correo o contraseña incorrectos';
      } else {
        student.value = s;
        _resetEvalState();
        Get.offAllNamed('/student/courses');
      }
    } catch (_) {
      authError.value = 'Error al conectar con la base de datos';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(
      String name, String email, String password) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final s = await _authRepo.register(name, email, password);
      student.value = s;
      _resetEvalState();
      Get.offAllNamed('/student/courses');
    } catch (_) {
      authError.value = 'El correo ya está registrado';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    student.value = null;
    _resetEvalState();
    Get.offAllNamed('/student/login');
  }

  // ── Courses (mock) ────────────────────────────────────────────────────────
  final activeEval = const ActiveEvaluation(
    id: 'eval1',
    title: 'Sprint 2 Review',
    courseAndDeadline: 'Desarrollo Móvil · Cierra en 12h',
    completedCount: 0,
    totalCount: 3,
  ).obs;

  final courses = <Course>[
    const Course(
        id: 'c1',
        name: 'Desarrollo Móvil 2026-10',
        groupName: 'Equipo Ágil 3',
        memberCount: 4),
    const Course(
        id: 'c2',
        name: 'Ingeniería de Software 2026-10',
        groupName: 'Grupo Beta',
        memberCount: 3),
  ].obs;

  // ── Eval list ─────────────────────────────────────────────────────────────
  final peers = <Peer>[
    Peer(id: 'p1', name: 'Carlos López',   initials: 'CL'),
    Peer(id: 'p2', name: 'Ana Martínez',   initials: 'AM'),
    Peer(id: 'p3', name: 'Luis Rodríguez', initials: 'LR'),
  ].obs;

  int    get doneCount    => peers.where((p) => p.evaluated).length;
  int    get totalPeers   => peers.length;
  double get evalProgress => totalPeers == 0 ? 0 : doneCount / totalPeers;
  bool   get allEvaluated => doneCount == totalPeers;

  // ── Peer scoring ──────────────────────────────────────────────────────────
  Rx<Peer?> currentPeer = Rx<Peer?>(null);
  final scores = <String, int>{}.obs;

  void selectPeer(Peer peer) {
    currentPeer.value = peer;
    scores.assignAll(Map<String, int>.from(peer.scores));
  }

  void setScore(String criterionId, int score) => scores[criterionId] = score;

  bool get allCriteriaScored =>
      EvalCriterion.defaults.every((c) => scores.containsKey(c.id));

  void savePeerScore() {
    final peer = currentPeer.value;
    if (peer == null || !allCriteriaScored) return;
    peer.scores    = Map<String, int>.from(scores);
    peer.evaluated = true;
    peers.refresh();
    activeEval.value = ActiveEvaluation(
      id:                 activeEval.value.id,
      title:              activeEval.value.title,
      courseAndDeadline:  activeEval.value.courseAndDeadline,
      completedCount:     doneCount,
      totalCount:         totalPeers,
    );
  }

  void submitEvaluation() => peers.refresh();

  // ── My results (mock received scores) ────────────────────────────────────
  final myResults = <CriterionResult>[
    const CriterionResult(label: 'Puntualidad',    value: 4.5),
    const CriterionResult(label: 'Contribuciones', value: 3.8),
    const CriterionResult(label: 'Compromiso',     value: 4.3),
    const CriterionResult(label: 'Actitud',        value: 4.7),
  ];

  double get myAverage => myResults.isEmpty
      ? 0
      : myResults.map((r) => r.value).reduce((a, b) => a + b) /
          myResults.length;

  String get performanceBadge {
    final avg = myAverage;
    if (avg >= 4.5) return 'Excelente desempeño';
    if (avg >= 3.5) return 'Buen desempeño';
    if (avg >= 2.5) return 'Desempeño adecuado';
    return 'Necesita mejorar';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _resetEvalState() {
    for (final p in peers) {
      p.evaluated = false;
      p.scores    = {};
    }
    peers.refresh();
    currentPeer.value = null;
    scores.clear();
    activeEval.value = ActiveEvaluation(
      id:                'eval1',
      title:             'Sprint 2 Review',
      courseAndDeadline: 'Desarrollo Móvil · Cierra en 12h',
      completedCount:    0,
      totalCount:        3,
    );
  }
}
