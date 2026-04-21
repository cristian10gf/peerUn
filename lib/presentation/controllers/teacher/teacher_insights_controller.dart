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

  final _overviewVm = Rx<TeacherDataInsightsViewModel?>(null);
  TeacherDataInsightsViewModel? get overviewVm => _overviewVm.value;

  static String _cacheKey(int teacherId) => 'teacher_insights_v1_$teacherId';

Future<void> loadInsights({bool forceRefresh = false}) async {
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

    loadError.value = '';

    // Estrategia Stale-While-Revalidate: Mostrar caché inmediatamente si existe
    if (!forceRefresh) {
      try {
        final cached = await _cache.get(_cacheKey(teacherId));
        if (cached != null) {
          final input = TeacherInsightsInput.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
          );
          final aggregate = _domainService.build(input);
          _overviewVm.value = _viewMapper.build(aggregate);
          // Refrescar listeners de variables reactivas si es necesario (el .obs de get builder se gatillará si hay dependencias directas)
        }
      } catch (_) {
        // Ignorar error de caché y forzar red
      }
    }

    // Mostrar loading solo si no hay datos en caché o es un refresh explícito
    if (_overviewVm.value == null || forceRefresh) {
      isLoading.value = true;
    }

    try {
      // Revalidación: Fetch de red (network)
      final input = await _evaluationRepository.getTeacherInsightsInput(teacherId);
      
      // Actualizar la caché en el fondo
      try {
        await _cache.set(_cacheKey(teacherId), jsonEncode(input.toJson()));
      } catch (_) {
        // Fallo de escritura caché no es fatal
      }

      // Actualizar UI ViewModel con datos frescos
      final aggregate = _domainService.build(input);
      _overviewVm.value = _viewMapper.build(aggregate);

      final now = DateTime.now();
      final previous = lastUpdatedAt.value;
      if (previous != null && !now.isAfter(previous)) {
        lastUpdatedAt.value = previous.add(const Duration(milliseconds: 1));
      } else {
        lastUpdatedAt.value = now;
      }
    } catch (e, stackTrace) {
      print("CRITICAL ERROR IN LOAD INSIGHTS: $e");
      print(stackTrace);
      if (_overviewVm.value == null) {
        // Solo mostrar error si no tenemos datos de caché disponibles para mantener UX fluida
        loadError.value = parseApiError(e, fallback: 'Error al cargar datos');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshInsights() async {
    await loadInsights(forceRefresh: true);
  }

  void resetState() {
    isLoading.value = false;
    loadError.value = '';
    _overviewVm.value = null;
    lastUpdatedAt.value = null;
  }
}
