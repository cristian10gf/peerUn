import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_best_group_section.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_category_average_section.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_course_average_section.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_insights_header.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_insights_state_cards.dart';
import 'package:example/presentation/pages/teacher/widgets/insights/teacher_student_rank_section.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TDataInsightsPage extends StatefulWidget {
  const TDataInsightsPage({super.key});

  @override
  State<TDataInsightsPage> createState() => _TDataInsightsPageState();
}

class _TDataInsightsPageState extends State<TDataInsightsPage> {
  late final TeacherInsightsController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TeacherInsightsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ctrl.loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Obx(
              () => TeacherInsightsHeader(
                onBackTap: () => Get.offNamed('/teacher/dash'),
                onRefreshTap: _ctrl.refreshInsights,
                lastUpdatedAt: _ctrl.lastUpdatedAt.value,
              ),
            ),
            const Divider(height: 1, color: tkBorder),
            Expanded(
              child: Obx(() {
                if (_ctrl.isLoading.value) {
                  return const TeacherInsightsLoadingStateCard();
                }

                if (_ctrl.loadError.value.isNotEmpty) {
                  return TeacherInsightsErrorStateCard(
                    message: _ctrl.loadError.value,
                    onRetry: _ctrl.refreshInsights,
                  );
                }

                final vm = _ctrl.overviewVm;
                if (vm == null) {
                  return const TeacherInsightsLoadingStateCard();
                }

                if (vm.showNoEvaluationsState) {
                  return TeacherInsightsNoEvaluationsStateCard(
                    onCreateEvaluation: () => Get.offNamed('/teacher/new-eval'),
                  );
                }

                if (vm.showNoResponsesState) {
                  return const TeacherInsightsNoResponsesStateCard();
                }

                return SingleChildScrollView(
                  key: const Key('teacher-insights-scroll'),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InsightsOverviewStatsRow(vm: vm),
                      const SizedBox(height: 20),
                      TeacherCourseAverageSection(items: vm.courseAverages),
                      const SizedBox(height: 18),
                      TeacherCategoryAverageSection(items: vm.categoryAverages),
                      const SizedBox(height: 18),
                      TeacherBestGroupSection(items: vm.bestGroups),
                      const SizedBox(height: 18),
                      TeacherStudentRankSection(
                        title: 'TOP ESTUDIANTES',
                        emptyMessage: 'Sin estudiantes elegibles',
                        items: vm.topStudents,
                      ),
                      const SizedBox(height: 18),
                      TeacherStudentRankSection(
                        title: 'EN RIESGO',
                        emptyMessage: 'Sin estudiantes en riesgo',
                        items: vm.atRiskStudents,
                        highlightRisk: true,
                      ),
                      const SizedBox(height: 18),
                      _EvaluationsCoverageSection(items: vm.evaluations),
                    ],
                  ),
                );
              }),
            ),
            const TeacherBottomNav(activeIndex: 2),
          ],
        ),
      ),
    );
  }
}

class _InsightsOverviewStatsRow extends StatelessWidget {
  final TeacherDataInsightsViewModel vm;

  const _InsightsOverviewStatsRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: vm.overallAverageLabel,
            label: 'PROMEDIO GLOBAL',
            valueColor: tkGold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: vm.evaluationsCountLabel,
            label: 'EVALUACIONES',
            valueColor: tkSuccess,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            value: vm.validScoresCountLabel,
            label: 'MUESTRAS',
            valueColor: tkBlue,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: tkTextFaint,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluationsCoverageSection extends StatelessWidget {
  final List<TeacherInsightsEvaluationCoverageVm> items;

  const _EvaluationsCoverageSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EVALUACIONES CONSIDERADAS',
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tkTextFaint,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tkSurface,
              border: Border.all(color: tkBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Sin evaluaciones en el alcance actual',
              style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
            ),
          )
        else
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tkSurface,
                border: Border.all(color: tkBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.evaluationName,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.courseName} · ${item.categoryName}',
                    style: GoogleFonts.dmMono(fontSize: 10, color: tkTextFaint),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
