import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/widgets/student_back_button.dart';
import 'package:example/presentation/pages/student/widgets/student_criterion_palette.dart';
import 'package:example/presentation/pages/student/widgets/student_results_average_card.dart';
import 'package:example/presentation/pages/student/widgets/student_results_criterion_card.dart';

class SMyResultsPage extends StatelessWidget {
  const SMyResultsPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentBackButton(label: 'Volver', route: '/student/courses'),
                  const SizedBox(height: 14),
                  Text(
                    'Mis resultados',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: skText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(() {
                    final eval = ctrl.activeEvalDb.value;
                    final label = eval == null
                        ? 'Sin evaluación'
                        : '${eval.name} · ${eval.visibility == 'public' ? 'Visibilidad pública' : 'Privada'}';
                    return Text(
                      label,
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: skTextFaint,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: skBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.isLoadingMyResults.value && ctrl.myResults.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: skPrimary,
                      strokeWidth: 2,
                    ),
                  );
                }

                return RefreshIndicator(
                  key: const Key('student-results-refresh-indicator'),
                  onRefresh: ctrl.refreshMyResults,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    key: const Key('student-results-scroll'),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudentResultsAverageCard(
                          average: ctrl.myAverage,
                          badge: ctrl.performanceBadge,
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'DESGLOSE POR CRITERIO',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: skTextFaint,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (ctrl.myResultsError.value.isNotEmpty &&
                            ctrl.myResults.isEmpty)
                          _StudentResultsErrorCard(
                            message: ctrl.myResultsError.value,
                          )
                        else if (ctrl.myResults.isEmpty)
                          const _StudentResultsEmptyCard()
                        else
                          Column(
                            children: ctrl.myResults
                                .asMap()
                                .entries
                                .map(
                                  (e) => StudentResultsCriterionCard(
                                    result: e.value,
                                    color:
                                        StudentCriterionPalette.colors[e.key %
                                            StudentCriterionPalette
                                                .colors
                                                .length],
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentResultsErrorCard extends StatelessWidget {
  final String message;

  const _StudentResultsErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 30, color: critAmber),
          const SizedBox(height: 10),
          Text(
            'No se pudieron cargar tus resultados',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: skText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.sora(fontSize: 11, color: skTextFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StudentResultsEmptyCard extends StatelessWidget {
  const _StudentResultsEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 32, color: skTextFaint),
          const SizedBox(height: 10),
          Text(
            'Sin resultados aún',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: skText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tus notas aparecerán cuando se registren evaluaciones válidas',
            style: GoogleFonts.sora(fontSize: 11, color: skTextFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
