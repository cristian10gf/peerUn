import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/pages/student/widgets/student_back_button.dart';
import 'package:example/presentation/pages/student/widgets/student_criterion_palette.dart';
import 'package:example/presentation/pages/student/widgets/student_peer_score_criterion_card.dart';
import 'package:example/presentation/pages/student/widgets/student_peer_score_submit_button.dart';

class SPeerScorePage extends StatelessWidget {
  const SPeerScorePage({super.key});

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
                  StudentBackButton(
                    label: 'Compañeros',
                    route: '/student/peers',
                  ),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                peer.name,
                                style: GoogleFonts.sora(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: skText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                    ...EvalCriterion.defaults.asMap().entries.map(
                      (e) => StudentPeerScoreCriterionCard(
                        criterion: e.value,
                        ctrl: ctrl,
                        color:
                            StudentCriterionPalette.colors[e.key %
                                StudentCriterionPalette.colors.length],
                      ),
                    ),
                    const SizedBox(height: 4),
                    StudentPeerScoreSubmitButton(ctrl: ctrl),
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
