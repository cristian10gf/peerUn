import 'package:get/get.dart';
import 'package:example/domain/models/student.dart';
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
  final evaluations      = <Evaluation>[].obs;

  Future<void> loadEvalData() async {
    final s = student.value;
    if (s == null) return;

    // Load all evaluations this student is part of
    List<Evaluation> evalList = [];
    try {
      evalList = await _evalRepo.getEvaluationsForStudent(s.email);
      evaluations.assignAll(evalList);
    } catch (_) {}

    // Pick first active eval (or most recent) as default context
    final Evaluation? eval = evalList.firstWhereOrNull((e) => e.isActive) ??
        (evalList.isNotEmpty ? evalList.first : null);

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

  Future<void> _loadGroupAndPeers(Evaluation eval, dynamic s) async {
    try {
      final gName = await _evalRepo.getGroupNameForStudent(eval.id, s.email);
      currentGroupName.value = gName ?? eval.categoryName;
    } catch (_) {
      currentGroupName.value = eval.categoryName;
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
    } catch (_) {}
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
    try {
      final gName = await _evalRepo.getGroupNameForStudent(eval.id, s.email);
      currentGroupName.value = gName ?? eval.categoryName;
    } catch (_) {
      currentGroupName.value = eval.categoryName;
    }
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
    peers.refresh();
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
    evaluations.clear();
    peers.clear();
    myResults.clear();
    currentPeer.value = null;
    scores.clear();
  }
}
