import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/constants/evaluation_ui_constants.dart';
import 'package:example/domain/models/teacher_data.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_state_cards.dart';
import 'package:google_fonts/google_fonts.dart';

Color _tkScore(double v) => v >= 4.0 ? const Color(0xFF4CB050) : const Color(0xFFF5A623);
const _kAvatarColors = [
  Color(0xFF4A90E2),
  Color(0xFF9C27B0),
  Color(0xFF4CB050),
  Color(0xFFE91E63)
];

class TResultsPage extends StatelessWidget {
  const TResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherResultsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Obx(() {
          final drill = ctrl.selectedGroupIndex;
          return Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TeacherBackButton(
                          key: const Key('results-back-button'),
                          backgroundColor: const Color(0xFFE0E0E0),
                          iconColor: Colors.black87,
                          onTap: () {
                            if (drill != null) {
                              ctrl.closeGroupDetail();
                            } else {
                              Get.back();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      drill != null
                          ? ctrl.groupResults[drill].name
                          : 'Resultados',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(() {
                      final evalName = ctrl.selectedEval.value?.name ?? '—';
                      return Text(
                        '$evalName · ${drill != null ? 'Desglose completo' : 'Vista general'}',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.black12),

              // ── Body ─────────────────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (ctrl.resultsLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B83EB),
                        strokeWidth: 2,
                      ),
                    );
                  }

                  if (ctrl.resultsError.value.isNotEmpty) {
                    return RefreshIndicator(
                      key: const Key('results-refresh-indicator'),
                      onRefresh: ctrl.refreshResults,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          TeacherResultsErrorStateCard(
                            message: ctrl.resultsError.value,
                          ),
                        ],
                      ),
                    );
                  }

                  final d = ctrl.selectedGroupIndex;
                  return RefreshIndicator(
                    key: const Key('results-refresh-indicator'),
                    onRefresh: ctrl.refreshResults,
                    child: d == null
                        ? _OverviewBody(ctrl: ctrl)
                        : _DetailBody(ctrl: ctrl, group: ctrl.groupResults[d]),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────

class _OverviewBody extends StatelessWidget {
  final TeacherResultsController ctrl;
  const _OverviewBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('results-overview-panel'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: ctrl.groupResults.isEmpty
                        ? '—'
                        : ctrl.overallAverage.toStringAsFixed(1),
                    label: 'PROMEDIO GENERAL',
                    valueColor: const Color(0xFF7B83EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: ctrl.groupResults.length.toString(),
                    label: 'GRUPOS',
                    valueColor: const Color(0xFF4CB050),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'GRUPOS — toca para detalle',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          Obx(() {
            if (ctrl.groupResults.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.inbox_outlined,
                      size: 32,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sin respuestas aún',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Los resultados aparecerán cuando los\nestudiantes envíen sus evaluaciones',
                      style: GoogleFonts.sora(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: ctrl.groupResults
                  .asMap()
                  .entries
                  .map(
                    (e) => _GroupCard(
                      index: e.key,
                      group: e.value,
                      onTap: () => ctrl.openGroupDetail(e.key),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final int index;
  final GroupResult group;
  final VoidCallback onTap;
  const _GroupCard({
    required this.index,
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('results-group-card-$index'),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              group.name,
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Row(
              children: [
                Text(
                  "Promedio:",
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _tkScore(group.average).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    group.average.toStringAsFixed(1),
                    style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _tkScore(group.average),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail ────────────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  final TeacherResultsController ctrl;
  final GroupResult group;
  const _DetailBody({required this.ctrl, required this.group});

  static final _ringColors = EvaluationUiConstants.criteriaColors
      .map((v) => Color(v.toInt()))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('results-detail-panel'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (i) => _CriterionRing(
                  value: group.criteria[i],
                  label: EvaluationUiConstants.criteriaLabels[i],
                  color: _ringColors[i],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'ESTUDIANTES',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          ...group.students.asMap().entries.map(
            (e) => _StudentCard(
              student: e.value,
              avatarColor: _kAvatarColors[e.key % 4],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRing extends StatelessWidget {
  final double value;
  final String label;
  final Color color;
  const _CriterionRing({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: ((value - 2) / 3).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 4,
              ),
              Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentResult student;
  final Color avatarColor;
  const _StudentCard({required this.student, required this.avatarColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              student.initial,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              student.name,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            student.score.toStringAsFixed(1),
            style: GoogleFonts.dmMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _tkScore(student.score),
            ),
          ),
        ],
      ),
    );
  }
}

