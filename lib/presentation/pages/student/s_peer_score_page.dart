import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/domain/models/peer_evaluation.dart';

class SPeerScorePage extends StatelessWidget {
  const SPeerScorePage({super.key});

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
                  _BackButton(label: 'Lista', route: '/student/eval-list'),
                  const SizedBox(height: 14),
                  Obx(() {
                    final peer = ctrl.currentPeer.value;
                    if (peer == null) return const SizedBox.shrink();
                    final scored = EvalCriterion.defaults
                        .where((c) => ctrl.scores.containsKey(c.id))
                        .length;
                    return Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: skPrimaryLight,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            peer.initials,
                            style: GoogleFonts.dmMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: skPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              peer.name,
                              style: GoogleFonts.sora(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: skText,
                              ),
                            ),
                            Text(
                              '$scored/4 criterios',
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: skTextFaint,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  children: [
                    ...EvalCriterion.defaults
                        .asMap()
                        .entries
                        .map((e) => _CriterionCard(
                              criterion: e.value,
                              ctrl:      ctrl,
                              color:     _critColors[e.key],
                            )),
                    const SizedBox(height: 4),
                    _SubmitButton(ctrl: ctrl),
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

class _CriterionCard extends StatelessWidget {
  final EvalCriterion criterion;
  final StudentController ctrl;
  final Color color;
  const _CriterionCard({required this.criterion, required this.ctrl, required this.color});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Obx(() {
            final score = ctrl.scores[criterion.id];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  criterion.label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
                if (score != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score.0',
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 10),

          // Score buttons
          Row(
            children: [2, 3, 4, 5].map((val) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: val < 5 ? 5 : 0,
                  ),
                  child: Obx(() {
                    final selected = ctrl.scores[criterion.id] == val;
                    return GestureDetector(
                      onTap: () => ctrl.setScore(criterion.id, val),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? color : skSurface,
                          border: Border.all(
                            color: selected ? color : skBorder,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$val',
                          style: GoogleFonts.dmMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                selected ? Colors.white : skTextFaint,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Level description
          Obx(() {
            final score = ctrl.scores[criterion.id];
            return Center(
              child: Text(
                score != null
                    ? EvalCriterion.levelFor(score).toUpperCase()
                    : '— SELECCIONA UN NIVEL —',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: skTextFaint,
                  letterSpacing: 0.3,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final StudentController ctrl;
  const _SubmitButton({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready = ctrl.allCriteriaScored;
      return GestureDetector(
      onTap: ready
          ? () {
              ctrl.savePeerScore();
              Get.offNamed('/student/eval-list');
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: ready ? skPrimary : skBorder,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          ready ? 'Guardar y continuar' : 'Completa los 4 criterios',
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ready ? Colors.white : skTextFaint,
          ),
        ),
      ),
    );
    });
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
