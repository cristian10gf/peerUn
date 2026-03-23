import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/presentation/pages/student/widgets/student_bottom_nav.dart';
import 'package:example/presentation/pages/student/widgets/student_course_header.dart';

class SEvalListPage extends StatelessWidget {
  const SEvalListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StudentController>();
    return Scaffold(
      backgroundColor: skBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: skSurface,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              child: Text(
                'Historial',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: skText,
                ),
              ),
            ),
            const Divider(height: 1, color: skBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                final evals = ctrl.evaluations;
                if (evals.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 40,
                            color: skTextFaint,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Sin historial',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: skTextMid,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Las evaluaciones en las que participes\naparecerán aquí',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: skTextFaint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final grouped = ctrl.groupedAllEvaluationsByCourse;
                final sections = grouped.entries.toList();
                // Build flat list of widgets: [header?, item, item, ...]
                final widgets = <Widget>[];
                for (final entry in sections) {
                  if (sections.length > 1) {
                    widgets.add(StudentCourseHeader(name: entry.key));
                    widgets.add(const SizedBox(height: 8));
                  }
                  for (final e in entry.value) {
                    widgets.add(_HistorialItem(eval: e, ctrl: ctrl));
                    widgets.add(const SizedBox(height: 10));
                  }
                }
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: widgets,
                );
              }),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            StudentBottomNav(activeIndex: 1),
          ],
        ),
      ),
    );
  }
}

class _HistorialItem extends StatelessWidget {
  final Evaluation eval;
  final StudentController ctrl;
  const _HistorialItem({required this.eval, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final date =
        '${eval.createdAt.day}/${eval.createdAt.month}/${eval.createdAt.year}';

    return Obx(() {
      final badge = ctrl.statusBadgeInfoFor(eval);
      final showEvaluarBtn = ctrl.canEvaluate(eval);
      final borderColor = ctrl.statusBorderColorFor(eval);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skSurface,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    eval.name,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: skText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badge.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge.label,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badge.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${eval.categoryName} · $date',
              style: GoogleFonts.dmMono(fontSize: 11, color: skTextFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (showEvaluarBtn) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await ctrl.selectEvalForEvaluation(eval);
                        Get.toNamed('/student/peers');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: skPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Evaluar',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await ctrl.selectEvalForResults(eval);
                      Get.toNamed('/student/results');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: skSurface,
                        border: Border.all(color: skBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ver resultados',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: skPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
