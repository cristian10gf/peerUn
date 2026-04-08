import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/services/evaluation_domain_service.dart';
import 'package:example/presentation/theme/app_colors.dart';

typedef StudentStatusBadge = ({
  String label,
  Color textColor,
  Color backgroundColor,
});

class StudentController extends GetxController {
  final IAuthRepository        _authRepo;
  final IEvaluationRepository  _evalRepo;
  final EvaluationDomainService _evaluationDomainService;

  StudentController(
    this._authRepo,
    this._evalRepo, {
    EvaluationDomainService? evaluationDomainService,
  }) : _evaluationDomainService =
           evaluationDomainService ?? const EvaluationDomainService();

  // ── Auth ──────────────────────────────────────────────────────────────────
  final student    = Rx<Student?>(null);
  final isLoading  = false.obs;
  final authError  = ''.obs;

  String _friendlyRegisterError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.isEmpty) return 'No se pudo completar el registro';
    if (raw.contains('409') || raw.toLowerCase().contains('registrado')) {
      return 'El correo ya esta registrado';
    }
    return raw;
  }

  Student get currentStudent => student.value!;
  bool get isLoggedIn => student.value != null;

  @override
  void onInit() {
    super.onInit();
    ever(student, (s) {
      if (s != null) loadEvalData();
    });
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    try {
      student.value = await _authRepo.getCurrentSession();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> activateSessionFromLogin() async {
    await checkSession();
  }

  void clearSessionStateForRoleSwitch() {
    student.value = null;
    authError.value = '';
    evalLoadError.value = '';
    peerLoadError.value = '';
    myResultsError.value = '';
    submitError.value = '';
    _resetEvalState();
  }

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final s = await _authRepo.register(name, email, password);
      student.value = s;
      Get.offAllNamed('/student/courses');
    } catch (e) {
      authError.value = _friendlyRegisterError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _authRepo.logout();
    student.value = null;
    _resetEvalState();
    Get.offAllNamed('/login');
  }

  // ── Eval data from DB ─────────────────────────────────────────────────────
  final activeEvalDb     = Rx<Evaluation?>(null);
  final currentGroupName = ''.obs;
  final hasActiveEval    = false.obs;
  final evaluations      = <Evaluation>[].obs;
  final evalStatuses     = <int, EvalStudentStatus>{}.obs;
  final evalLoadError    = ''.obs;
  final homeLoadError    = ''.obs;
  final peerLoadError    = ''.obs;
  final myResultsError   = ''.obs;
  final submitError      = ''.obs;
  final isLoadingHome    = false.obs;

  final homeCourses = <StudentHomeCourse>[].obs;
  final expandedCourseIds = <int>{}.obs;
  final expandedCategoryIds = <int>{}.obs;

  bool isCourseExpanded(int courseId) => expandedCourseIds.contains(courseId);
  bool isCategoryExpanded(int categoryId) => expandedCategoryIds.contains(categoryId);

  void toggleCourseExpanded(int courseId) {
    if (expandedCourseIds.contains(courseId)) {
      expandedCourseIds.remove(courseId);
    } else {
      expandedCourseIds.add(courseId);
    }
    expandedCourseIds.refresh();
  }

  void toggleCategoryExpanded(int categoryId) {
    if (expandedCategoryIds.contains(categoryId)) {
      expandedCategoryIds.remove(categoryId);
    } else {
      expandedCategoryIds.add(categoryId);
    }
    expandedCategoryIds.refresh();
  }

  Future<void> openActiveEvaluationForCategory(StudentHomeCategory category) async {
    if (!category.hasActiveEvaluation) return;

    final target = evaluations
        .where((e) => e.categoryId == category.id && canEvaluate(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (target.isEmpty) return;
    await selectEvalForEvaluation(target.first);
    Get.toNamed('/student/peers');
  }

  List<Evaluation> get pendingEvaluationsSorted {
    return evaluations
        .where((e) => evalStatuses[e.id] == EvalStudentStatus.activePending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Evaluation> get activeEvaluations {
    return evaluations.where((e) => e.isActive).toList();
  }

  Map<String, List<Evaluation>> get groupedAllEvaluationsByCourse {
    return _groupEvaluationsByCourse(evaluations);
  }

  Map<String, List<Evaluation>> get groupedActiveEvaluationsByCourse {
    return _groupEvaluationsByCourse(activeEvaluations);
  }

  EvalStudentStatus? statusFor(Evaluation eval) => evalStatuses[eval.id];

  bool canEvaluate(Evaluation eval) {
    return statusFor(eval) == EvalStudentStatus.activePending;
  }

  StudentStatusBadge statusBadgeInfoFor(Evaluation eval) {
    final status = statusFor(eval);
    return switch (status) {
      EvalStudentStatus.activePending => (
        label: 'ACTIVA',
        textColor: skPrimary,
        backgroundColor: skPrimaryLight,
      ),
      EvalStudentStatus.activeCompleted => (
        label: 'ACTIVA · REALIZADA',
        textColor: critGreen,
        backgroundColor: const Color(0xFFD1FAE5),
      ),
      EvalStudentStatus.closedNotDone => (
        label: 'FINALIZADA · NO REALIZADA',
        textColor: const Color(0xFFEF4444),
        backgroundColor: const Color(0xFFFEF2F2),
      ),
      EvalStudentStatus.closedCompleted => (
        label: 'FINALIZADA',
        textColor: skTextFaint,
        backgroundColor: skSurfaceAlt,
      ),
      null => eval.isActive
          ? (
              label: 'ACTIVA',
              textColor: skPrimary,
              backgroundColor: skPrimaryLight,
            )
          : (
              label: 'CERRADA',
              textColor: skTextFaint,
              backgroundColor: skSurfaceAlt,
            ),
    };
  }

  Color statusBorderColorFor(Evaluation eval) {
    return switch (statusFor(eval)) {
      EvalStudentStatus.activePending => skPrimaryMid,
      EvalStudentStatus.activeCompleted => critGreen,
      EvalStudentStatus.closedNotDone => const Color(0xFFFECACA),
      _ => skBorder,
    };
  }

  Map<String, List<Evaluation>> _groupEvaluationsByCourse(
    List<Evaluation> source,
  ) {
    final grouped = <String, List<Evaluation>>{};
    for (final e in source) {
      final key = e.courseName.isNotEmpty ? e.courseName : 'Sin curso';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  Future<void> loadEvalData() async {
    final s = student.value;
    if (s == null) return;
    final studentId = int.parse(s.id);
    evalLoadError.value = '';
    homeLoadError.value = '';
    peerLoadError.value = '';
    myResultsError.value = '';
    submitError.value = '';

    isLoadingHome.value = true;
    try {
      final courses = await _evalRepo.getStudentHomeCourses(s.email);
      homeCourses.assignAll(courses);
      expandedCourseIds
        ..clear()
        ..addAll(courses.take(2).map((c) => c.id));
      expandedCategoryIds.clear();
    } catch (e) {
      homeCourses.clear();
      homeLoadError.value = parseApiError(e, fallback: 'Error al cargar cursos');
    } finally {
      isLoadingHome.value = false;
    }

    // Load all evaluations this student is part of
    List<Evaluation> evalList = [];
    try {
      evalList = await _evalRepo.getEvaluationsForStudent(s.email);
      evaluations.assignAll(evalList);
    } catch (e) {
      evalLoadError.value = parseApiError(e, fallback: 'Error al cargar evaluaciones');
      evaluations.clear();
    }

    // Compute per-eval completion status
    await _computeStatuses(evalList, s.email, studentId);

    // Pick first active+pending eval as default context, fallback to first active
    final eval = _evaluationDomainService.selectDefaultEvaluation(
      evalList,
      evalStatuses,
    );

    activeEvalDb.value = eval;

    if (eval == null) {
      hasActiveEval.value = false;
      peers.clear();
      myResults.clear();
      currentGroupName.value = '';
      return;
    }

    hasActiveEval.value = eval.isActive;
    await _loadGroupAndPeers(eval, s);
    await _loadMyResultsInternal(eval.id, s.email);
  }

  Future<void> _computeStatuses(
      List<Evaluation> evalList, String email, int studentId) async {
    final statuses = <int, EvalStudentStatus>{};
    for (final eval in evalList) {
      try {
        final completed = await _evalRepo.hasCompletedAllPeers(
          evalId:    eval.id,
          email:     email,
          studentId: studentId,
        );
        statuses[eval.id] = _evaluationDomainService.statusForEvaluation(
          evaluation: eval,
          completed: completed,
        );
      } catch (e) {
        statuses[eval.id] = _evaluationDomainService.statusForEvaluation(
          evaluation: eval,
          completed: false,
        );
        if (evalLoadError.value.isEmpty) {
          evalLoadError.value = parseApiError(e, fallback: 'No se pudo calcular el estado de algunas evaluaciones');
        }
      }
    }
    evalStatuses.assignAll(statuses);
  }

  Future<void> _loadGroupAndPeers(Evaluation eval, dynamic s) async {
    peerLoadError.value = '';
    try {
      final gName = await _evalRepo.getGroupNameForStudent(eval.id, s.email);
      currentGroupName.value = gName ?? eval.categoryName;
    } catch (e) {
      currentGroupName.value = eval.categoryName;
      peerLoadError.value = parseApiError(e, fallback: 'Error al cargar el grupo');
    }

    final studentId = int.parse(s.id);
    List<Peer> peerList = [];
    try {
      peerList = await _evalRepo.getPeersForStudent(eval.id, s.email);
      for (final p in peerList) {
        p.evaluated = await _evalRepo.hasEvaluated(
          evalId:             eval.id,
          evaluatorStudentId: studentId,
          evaluatedMemberId:  int.parse(p.id),
        );
      }
    } catch (e) {
      peerLoadError.value = parseApiError(e, fallback: 'Error al cargar pares');
    }
    peers.assignAll(peerList);
  }

  /// Select an eval for peer-scoring (loads peers, sets active eval).
  Future<void> selectEvalForEvaluation(Evaluation eval) async {
    final s = student.value;
    if (s == null) return;
    activeEvalDb.value     = eval;
    hasActiveEval.value    = eval.isActive;
    peers.clear();
    myResults.clear();
    await _loadGroupAndPeers(eval, s);
  }

  /// Select an eval to view results (loads my results, sets active eval).
  Future<void> selectEvalForResults(Evaluation eval) async {
    final s = student.value;
    if (s == null) return;
    activeEvalDb.value = eval;
    peerLoadError.value = '';
    try {
      final gName = await _evalRepo.getGroupNameForStudent(eval.id, s.email);
      currentGroupName.value = gName ?? eval.categoryName;
    } catch (e) {
      currentGroupName.value = eval.categoryName;
      peerLoadError.value = parseApiError(e, fallback: 'Error al cargar el grupo');
    }
    await _loadMyResultsInternal(eval.id, s.email);
  }

  Future<void> _loadMyResultsInternal(int evalId, String email) async {
    myResultsError.value = '';
    try {
      final results = await _evalRepo.getMyResults(evalId, email);
      myResults.assignAll(results);
    } catch (e) {
      myResultsError.value = parseApiError(e, fallback: 'Error al cargar resultados');
      myResults.clear();
    }
  }

  // ── Eval list ─────────────────────────────────────────────────────────────
  final peers = <Peer>[].obs;

  int get doneCount => _evaluationDomainService.donePeers(peers);
  int get totalPeers => _evaluationDomainService.totalPeers(peers);
  double get evalProgress => _evaluationDomainService.evalProgress(peers);
  bool get allEvaluated => _evaluationDomainService.allEvaluated(peers);

  // ── Peer scoring ──────────────────────────────────────────────────────────
  final currentPeer = Rx<Peer?>(null);
  final scores      = <String, int>{}.obs;

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
    _refreshActiveEvalCard();
  }

  Future<void> submitEvaluation() async {
    final s    = student.value;
    final eval = activeEvalDb.value;
    if (s == null || eval == null) return;

    submitError.value = '';
    final studentId = int.parse(s.id);
    var failedSaves = 0;
    for (final peer in peers) {
      if (peer.evaluated && peer.scores.isNotEmpty) {
        try {
          await _evalRepo.saveResponses(
            evalId:             eval.id,
            evaluatorStudentId: studentId,
            evaluatedMemberId:  int.parse(peer.id),
            scores:             peer.scores,
          );
        } catch (e) {
          failedSaves++;
          if (submitError.value.isEmpty) {
            submitError.value = parseApiError(e, fallback: 'Error al guardar algunas evaluaciones');
          }
        }
      }
    }
    if (failedSaves > 0) {
      submitError.value = 'No se pudieron guardar $failedSaves evaluaciones';
    }

    // TEST — write to test_submit and confirm via read.
    try {
      final scoresByPeer = <String, Map<String, int>>{};
      for (final peer in peers) {
        if (peer.scores.isNotEmpty) scoresByPeer[peer.name] = peer.scores;
      }
      await _evalRepo.testSaveSubmit(
        evaluatorEmail: s.email,
        scoresByPeerName: scoresByPeer,
      );
      final testRows = await _evalRepo.readTestTable();
      Get.snackbar(
        '[TEST] Insert OK',
        'Filas en test_submit: ${testRows.length}',
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '[TEST] Error insert',
        e.toString(),
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
    await _loadMyResultsInternal(eval.id, s.email);

    // Refresh status for this eval now that responses are saved
    try {
      final completed = await _evalRepo.hasCompletedAllPeers(
        evalId:    eval.id,
        email:     s.email,
        studentId: studentId,
      );
      evalStatuses[eval.id] = _evaluationDomainService.statusForEvaluation(
        evaluation: eval,
        completed: completed,
      );
    } catch (e) {
      submitError.value = submitError.value.isEmpty
          ? 'No se pudo actualizar el estado: $e'
          : submitError.value;
    }
  }

  // ── My results ────────────────────────────────────────────────────────────
  final myResults = <CriterionResult>[].obs;

  double get myAverage =>
      _evaluationDomainService.averageFromCriterionResults(myResults);

  String get performanceBadge =>
      _evaluationDomainService.performanceBadge(myAverage);

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _refreshActiveEvalCard() {
    peers.refresh();
  }

  void _resetEvalState() {
    activeEvalDb.value     = null;
    hasActiveEval.value    = false;
    currentGroupName.value = '';
    evaluations.clear();
    evalStatuses.clear();
    homeLoadError.value = '';
    peers.clear();
    homeCourses.clear();
    expandedCourseIds.clear();
    expandedCategoryIds.clear();
    myResults.clear();
    currentPeer.value = null;
    scores.clear();
  }
}
