import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/domain/models/peer_evaluation.dart';

class SMyResultsPage extends StatelessWidget {
  const SMyResultsPage({super.key});

  static const _critColors = [critBlue, critPurple, critGreen, critAmber];

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
                  _BackButton(label: 'Volver', route: '/student/courses'),
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
                  Text(
                    'Sprint 2 Review · Visibilidad pública',
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      color: skTextFaint,
                    ),
                  ),
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
                    _AverageCard(ctrl: ctrl),
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
                    ...ctrl.myResults
                        .asMap()
                        .entries
                        .map((e) => _CriterionResultCard(
                              result: e.value,
                              color:  _critColors[e.key],
                            )),
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

class _AverageCard extends StatelessWidget {
  final StudentController ctrl;
  const _AverageCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final avg = ctrl.myAverage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            avg.toStringAsFixed(2),
            style: GoogleFonts.dmMono(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: skPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Promedio general recibido',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: skTextFaint,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: skSuccess.withValues(alpha: 0.09),
              border: Border.all(color: skSuccess.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ctrl.performanceBadge,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: skSuccess,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionResultCard extends StatelessWidget {
  final CriterionResult result;
  final Color color;
  const _CriterionResultCard({required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
              ),
              Text(
                result.value.toString(),
                style: GoogleFonts.dmMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: result.barFraction,
              backgroundColor: skBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final String route;
  const _BackButton({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.offNamed(route),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: skSurfaceAlt,
          border: Border.all(color: skBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded,
                size: 14, color: skTextMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: skTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
