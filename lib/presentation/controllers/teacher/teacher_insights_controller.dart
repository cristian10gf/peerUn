import 'dart:convert';

import 'package:example/data/utils/error_parser.dart';
import 'package:example/domain/models/teacher_insights.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/services/i_cache_service.dart';
import 'package:example/domain/services/teacher_insights_domain_service.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';
import 'package:example/presentation/services/teacher_insights_view_mapper.dart';
import 'package:get/get.dart';

class TeacherInsightsController extends GetxController {
  final IEvaluationRepository _evaluationRepository;
  final TeacherInsightsDomainService _domainService;
  final TeacherInsightsViewMapper _viewMapper;
  final TeacherSessionController _sessionController;
  final ICacheService _cache;

  TeacherInsightsController(
    this._evaluationRepository,
    this._domainService,
    this._viewMapper,
    this._sessionController,
    this._cache,
  );

  final isLoading = false.obs;
  final loadError = ''.obs;
  final lastUpdatedAt = Rx<DateTime?>(null);

  TeacherDataInsightsViewModel? _overviewVm;
  TeacherDataInsightsViewModel? get overviewVm => _overviewVm;

  int? _lastTeacherId;

  static String _cacheKey(int teacherId) => 'teacher_insights_v1_$teacherId';

  Future<void> loadInsights() async {
    final teacher = _sessionController.teacher.value;
    if (teacher == null) {
      resetState();
      loadError.value = 'Sesion docente no disponible';
      return;
    }

    final teacherId = int.tryParse(teacher.id);
    if (teacherId == null) {
      resetState();
      loadError.value = 'Sesion docente invalida';
      return;
    }

    _lastTeacherId = teacherId;
    isLoading.value = true;
    loadError.value = '';

    try {
      TeacherInsightsInput input;

      final cached = await _cache.get(_cacheKey(teacherId));
      if (cached != null) {
        input = TeacherInsightsInput.fromJson(
          jsonDecode(cached) as Map<String, dynamic>,
        );
      } else {
        input = await _evaluationRepository.getTeacherInsightsInput(teacherId);
        try {
          await _cache.set(_cacheKey(teacherId), jsonEncode(input.toJson()));
        } catch (_) {
          // cache write failure is non-fatal
        }
      }

      final aggregate = _domainService.build(input);
      _overviewVm = _viewMapper.build(aggregate);

      final now = DateTime.now();
      final previous = lastUpdatedAt.value;
      if (previous != null && !now.isAfter(previous)) {
        lastUpdatedAt.value = previous.add(const Duration(milliseconds: 1));
      } else {
        lastUpdatedAt.value = now;
      }
    } catch (e) {
      _overviewVm = null;
      loadError.value = parseApiError(e, fallback: 'Error al cargar datos');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshInsights() async {
    final teacherId = _lastTeacherId;
    if (teacherId != null) {
      await _cache.invalidate(_cacheKey(teacherId));
    }
    await loadInsights();
  }

  void resetState() {
    isLoading.value = false;
    loadError.value = '';
    _overviewVm = null;
    lastUpdatedAt.value = null;
    _lastTeacherId = null;
  }
}
