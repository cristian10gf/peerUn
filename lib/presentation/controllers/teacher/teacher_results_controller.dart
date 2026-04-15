import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';

class TeacherResultsController extends GetxController {
  final IEvaluationRepository _evalRepo;
  final TeacherResultsViewMapper _viewMapper;

  TeacherResultsController(
    this._evalRepo, {
    TeacherResultsViewMapper viewMapper = const TeacherResultsViewMapper(),
  }) : _viewMapper = viewMapper;

  final _drill = Rx<int?>(null);
  final groupResults = <GroupResult>[].obs;
  final resultsLoading = false.obs;
  final selectedEval = Rx<Evaluation?>(null);
  final resultsError = ''.obs;

  int? get selectedGroupIndex => _drill.value;

  TeacherResultsOverviewVm get overviewVm => _viewMapper.buildOverview(groupResults);

  TeacherResultsDetailVm? get selectedDetailVm {
    final index = selectedGroupIndex;
    if (index == null || index < 0 || index >= groupResults.length) {
      return null;
    }
    return _viewMapper.buildDetail(groupResults[index]);
  }

  void openGroupDetail(int index) {
    if (index < 0 || index >= groupResults.length) {
      return;
    }
    _drill.value = index;
  }

  void closeGroupDetail() {
    _drill.value = null;
  }

  Future<void> loadGroupResults(Evaluation eval) async {
    selectedEval.value = eval;
    closeGroupDetail();
    resultsLoading.value = true;
    resultsError.value = '';
    try {
      final results = await _evalRepo.getGroupResults(eval.id);
      groupResults.assignAll(results);
    } catch (e) {
      groupResults.clear();
      resultsError.value = parseApiError(e, fallback: 'Error al cargar resultados');
    } finally {
      resultsLoading.value = false;
    }
  }

  double get overallAverage {
    if (groupResults.isEmpty) return 0;
    final nonZero = groupResults.where((g) => g.average > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.map((g) => g.average).reduce((a, b) => a + b) / nonZero.length;
  }

  void resetState() {
    closeGroupDetail();
    groupResults.clear();
    resultsLoading.value = false;
    selectedEval.value = null;
    resultsError.value = '';
  }
}
