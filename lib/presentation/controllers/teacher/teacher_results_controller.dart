import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class TeacherResultsController extends GetxController {
  final IEvaluationRepository _evalRepo;

  TeacherResultsController(this._evalRepo);

  final drill = Rx<int?>(null);
  final groupResults = <GroupResult>[].obs;
  final resultsLoading = false.obs;
  final selectedEval = Rx<Evaluation?>(null);
  final resultsError = ''.obs;

  Future<void> loadGroupResults(Evaluation eval) async {
    selectedEval.value = eval;
    drill.value = null;
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
    drill.value = null;
    groupResults.clear();
    resultsLoading.value = false;
    selectedEval.value = null;
    resultsError.value = '';
  }
}
