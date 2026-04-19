import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/pages/student/widgets/student_back_button.dart';
import 'package:example/presentation/pages/student/widgets/student_peer_card.dart';
import 'package:example/presentation/pages/student/widgets/student_progress_card.dart';

class SPeersPage extends StatelessWidget {
  const SPeersPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StudentBackButton(label: 'Volver'),
                  const SizedBox(height: 16),
                  Obx(
                    () => Text(
                      ctrl.activeEvalDb.value?.name ?? 'Evaluación',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: skText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(
                    () => Text(
                      '${ctrl.currentGroupName.value} · ${ctrl.doneCount}/${ctrl.totalPeers} evaluados',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: skTextFaint,
                      ),
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
                    // Progress card
                    Obx(
                      () => StudentProgressCard(
                        progress: ctrl.evalProgress,
                        percentage: (ctrl.evalProgress * 100).round(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'COMPAÑEROS A EVALUAR',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Peer cards
                    Obx(
                      () => Column(
                        children: ctrl.peers
                            .map(
                              (p) => StudentPeerCard(
                                peer: p,
                                onTap: () {
                                  ctrl.selectPeer(p);
                                  Get.toNamed('/student/peer-score');
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    // Submit button
                    Obx(() {
                      if (!ctrl.allEvaluated) return const SizedBox.shrink();
                      final submitting = ctrl.isSubmitting.value;
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: submitting
                                ? null
                                : () async {
                                    await ctrl.submitEvaluation();
                                    Get.offNamed('/student/courses');
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: submitting
                                    ? skPrimary.withValues(alpha: 0.5)
                                    : skPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Enviar evaluación completa',
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      );
                    }),
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
