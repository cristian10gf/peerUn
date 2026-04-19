import 'dart:convert';
import 'package:get/get.dart';
import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/services/teacher_results_view_mapper.dart';
import 'package:example/domain/services/i_cache_service.dart';

class TeacherResultsController extends GetxController {
  final IEvaluationRepository _evalRepo;
  final TeacherResultsViewMapper _viewMapper;
  final ICacheService _cache;

  TeacherResultsController(
    this._evalRepo,
    this._cache, {
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
      final key = 'teacher_results_v1_${eval.id}';
      final cached = await _cache.get(key);
      if (cached != null) {
        groupResults.assignAll(
          (jsonDecode(cached) as List)
              .map((e) => GroupResult.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      } else {
        final results = await _evalRepo.getGroupResults(eval.id);
        groupResults.assignAll(results);
        try {
          await _cache.set(key, jsonEncode(results.map((r) => r.toJson()).toList()));
        } catch (_) {
          // cache write failure is non-fatal
        }
      }
    } catch (e) {
      groupResults.clear();
      resultsError.value = parseApiError(e, fallback: 'Error al cargar resultados');
    } finally {
      resultsLoading.value = false;
    }
  }

  /// Clears cached results for the current eval and reloads from API.
  Future<void> refreshResults() async {
    final eval = selectedEval.value;
    if (eval == null) return;
    await _cache.invalidate('teacher_results_v1_${eval.id}');
    await loadGroupResults(eval);
  }

  double get overallAverage {
    if (groupResults.isEmpty) return 0;
    final nonZero = groupResults.where((g) => g.average > 0).toList();
    if (nonZero.isEmpty) return 0;
    return nonZero.map((g) => g.average).reduce((a, b) => a + b) / nonZero.length;
  }

  Future<void> resetState() async {
    final eval = selectedEval.value;
    if (eval != null) {
      await _cache.invalidate('teacher_results_v1_${eval.id}');
    }
    _drill.value = null;
    groupResults.clear();
    resultsLoading.value = false;
    selectedEval.value = null;
    resultsError.value = '';
  }
}
