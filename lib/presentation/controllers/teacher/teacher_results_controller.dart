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

  String _cacheKeyForEval(int evalId) => 'teacher_results_v1_$evalId';

Future<void> loadGroupResults(Evaluation eval, {bool forceRefresh = false}) async {
    selectedEval.value = eval;
    closeGroupDetail();

    final key = _cacheKeyForEval(eval.id);
    resultsError.value = '';

    // Always clear in-memory results first to prevent stale rows from a
    // previous evaluation from appearing when the new fetch fails.
    groupResults.clear();

    // Estrategia Stale-While-Revalidate: Cargar de caché inmediatamente para fluidez de UI
    if (!forceRefresh) {
      try {
        final cached = await _cache.get(key);
        if (cached != null) {
          final cachedList = (jsonDecode(cached) as List)
              .map((e) => GroupResult.fromJson(e as Map<String, dynamic>))
              .toList();
          groupResults.assignAll(cachedList);
        }
      } catch (_) {
        // Ignorado, forzará load de red
      }
    }

    // Mostrar loader explícito si no hay grupos (bloquea la pantalla)
    if (groupResults.isEmpty) {
      resultsLoading.value = true;
    }

    try {
      // Revalidación: Fetch en background para traer datos frescos de las coevaluaciones de los estudiantes
      final results = await _evalRepo.getGroupResults(eval.id);
      groupResults.assignAll(results);
      
      // Guardar a cache los nuevos datos devueltos por la base de datos
      try {
        await _cache.set(key, jsonEncode(results.map((r) => r.toJson()).toList()));
      } catch (_) {
        // Ignorar falla de escribir cache
      }
    } catch (e, stackTrace) {
      print("CRITICAL ERROR IN LOAD GROUP RESULTS: $e");
      print(stackTrace);
      // Mantener los resultados en pantalla (caché) si falla el fetch en el framework
      if (groupResults.isEmpty) {
        groupResults.clear();
        resultsError.value = parseApiError(e, fallback: 'Error al cargar resultados');
      }
    } finally {
      resultsLoading.value = false;
    }
  }

  /// Clears cached results for the current eval and reloads from API.
  Future<void> refreshResults() async {
    final eval = selectedEval.value;
    if (eval == null) return;
    await _cache.invalidate(_cacheKeyForEval(eval.id));
    await loadGroupResults(eval, forceRefresh: true);
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
      await _cache.invalidate(_cacheKeyForEval(eval.id));
    }
    _drill.value = null;
    groupResults.clear();
    resultsLoading.value = false;
    selectedEval.value = null;
    resultsError.value = '';
  }
}
