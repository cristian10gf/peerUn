import 'package:get/get.dart';
import 'package:example/domain/models/student.dart';
import 'package:example/domain/models/course.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class StudentController extends GetxController {
  final IAuthRepository        _authRepo;
  final IEvaluationRepository  _evalRepo;

  StudentController(this._authRepo, this._evalRepo);

  // ── Auth ──────────────────────────────────────────────────────────────────
  final student    = Rx<Student?>(null);
  final isLoading  = false.obs;
  final authError  = ''.obs;

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

  Future<void> register(String name, String email, String password) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final s = await _authRepo.register(name, email, password);
      student.value = s;
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
    Get.offAllNamed('/login');
  }

  // ── Eval data from DB ─────────────────────────────────────────────────────
  final activeEvalDb     = Rx<Evaluation?>(null);
  final currentGroupName = ''.obs;
  final hasActiveEval    = false.obs;

  // ActiveEvaluation UI model (for the card in courses page)
  final activeEval = Rx<ActiveEvaluation>(const ActiveEvaluation(
    id: '', title: 'Sin evaluación activa',
    courseAndDeadline: '', completedCount: 0, totalCount: 0,
  ));

  // Courses derived from group memberships
  final courses = <Course>[].obs;

  Future<void> loadEvalData() async {
    final s = student.value;
    if (s == null) return;

    // Load courses (groups student belongs to)
    try {
      final c = await _evalRepo.getCoursesForStudent(s.email);
      courses.assignAll(c);
    } catch (_) {}

    // Load latest eval linked to this student
    Evaluation? eval;
    try {
      eval = await _evalRepo.getLatestForStudent(s.email);
    } catch (_) {}

    activeEvalDb.value = eval;

    if (eval == null) {
      hasActiveEval.value = false;
      peers.clear();
      myResults.clear();
      currentGroupName.value = '';
      return;
    }

    // Group name
    try {
      final gName = await _evalRepo.getGroupNameForStudent(eval.id, s.email);
      currentGroupName.value = gName ?? eval.categoryName;
    } catch (_) {
      currentGroupName.value = eval.categoryName;
    }

    // Load peers and check which are already evaluated
    final studentId = int.parse(s.id);
    List<Peer> peerList = [];
    try {
      peerList = await _evalRepo.getPeersForStudent(eval.id, s.email);
      for (final p in peerList) {
        p.evaluated = await _evalRepo.hasEvaluated(
          evalId:              eval.id,
          evaluatorStudentId:  studentId,
          evaluatedMemberId:   int.parse(p.id),
        );
      }
    } catch (_) {}
    peers.assignAll(peerList);

    // Active eval card
    hasActiveEval.value = eval.isActive;
    final closesIn    = eval.closesAt.difference(DateTime.now());
    final closesLabel = _formatDuration(closesIn);
    activeEval.value = ActiveEvaluation(
      id:                eval.id.toString(),
      title:             eval.name,
      courseAndDeadline: '${currentGroupName.value} · $closesLabel',
      completedCount:    peerList.where((p) => p.evaluated).length,
      totalCount:        peerList.length,
    );

    // Load my results
    await _loadMyResultsInternal(eval.id, s.email);
  }

  Future<void> _loadMyResultsInternal(int evalId, String email) async {
    try {
      final results = await _evalRepo.getMyResults(evalId, email);
      myResults.assignAll(results);
    } catch (_) {}
  }

  // ── Eval list ─────────────────────────────────────────────────────────────
  final peers = <Peer>[].obs;

  int get doneCount   => peers.where((p) => p.evaluated).length;
  int get totalPeers  => peers.length;
  double get evalProgress => totalPeers == 0 ? 0 : doneCount / totalPeers;
  bool get allEvaluated   => totalPeers > 0 && doneCount == totalPeers;

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

    final studentId = int.parse(s.id);
    for (final peer in peers) {
      if (peer.evaluated && peer.scores.isNotEmpty) {
        try {
          await _evalRepo.saveResponses(
            evalId:             eval.id,
            evaluatorStudentId: studentId,
            evaluatedMemberId:  int.parse(peer.id),
            scores:             peer.scores,
          );
        } catch (_) {}
      }
    }
    await _loadMyResultsInternal(eval.id, s.email);
  }

  // ── My results ────────────────────────────────────────────────────────────
  final myResults = <CriterionResult>[].obs;

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
  void _refreshActiveEvalCard() {
    final eval = activeEvalDb.value;
    if (eval == null) return;
    final closesIn    = eval.closesAt.difference(DateTime.now());
    final closesLabel = _formatDuration(closesIn);
    activeEval.value = ActiveEvaluation(
      id:                eval.id.toString(),
      title:             eval.name,
      courseAndDeadline: '${currentGroupName.value} · $closesLabel',
      completedCount:    doneCount,
      totalCount:        totalPeers,
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0)  return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }

  void _resetEvalState() {
    activeEvalDb.value     = null;
    hasActiveEval.value    = false;
    currentGroupName.value = '';
    peers.clear();
    myResults.clear();
    currentPeer.value = null;
    scores.clear();
    courses.clear();
    activeEval.value = const ActiveEvaluation(
      id: '', title: 'Sin evaluación activa',
      courseAndDeadline: '', completedCount: 0, totalCount: 0,
    );
  }
}
