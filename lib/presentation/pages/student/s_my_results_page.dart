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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Average card
                    Obx(
                      () => StudentResultsAverageCard(
                        average: ctrl.myAverage,
                        badge: ctrl.performanceBadge,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section label
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

                    // Criteria cards
                    Obx(
                      () => Column(
                        children: ctrl.myResults
                            .asMap()
                            .entries
                            .map(
                              (e) => StudentResultsCriterionCard(
                                result: e.value,
                                color:
                                    StudentCriterionPalette.colors[e.key %
                                        StudentCriterionPalette.colors.length],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
