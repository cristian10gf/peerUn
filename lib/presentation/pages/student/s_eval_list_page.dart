import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/domain/models/peer_evaluation.dart';

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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(label: 'Volver', route: '/student/courses'),
                  const SizedBox(height: 16),
                  Text(
                    'Sprint 2 Review',
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: skText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Obx(() => Text(
                        'Equipo Ágil 3 · ${ctrl.doneCount}/${ctrl.totalPeers} evaluados',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: skTextFaint,
                        ),
                      )),
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
                    // Time / progress card
                    Obx(() => _ProgressCard(
                          progress: ctrl.evalProgress,
                          percentage:
                              (ctrl.evalProgress * 100).round(),
                        )),
                    const SizedBox(height: 18),

                    // Section label
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
                    Obx(() => Column(
                          children: ctrl.peers
                              .map((p) => _PeerCard(
                                    peer: p,
                                    onTap: () {
                                      ctrl.selectPeer(p);
                                      Get.toNamed('/student/peer-score');
                                    },
                                  ))
                              .toList(),
                        )),

                    // Submit button
                    Obx(() {
                      if (!ctrl.allEvaluated) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              ctrl.submitEvaluation();
                              Get.offNamed('/student/courses');
                            },
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: skPrimary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(
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

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int percentage;
  const _ProgressCard({required this.progress, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: skTextMid),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cierra en 12h 30m',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.dmMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: skPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: skBorder,
              valueColor: const AlwaysStoppedAnimation(skPrimary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeerCard extends StatelessWidget {
  final Peer peer;
  final VoidCallback onTap;
  const _PeerCard({required this.peer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: peer.evaluated ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: peer.evaluated ? skPrimaryLight : skSurface,
          border: Border.all(
            color: peer.evaluated ? skPrimaryMid : skBorder,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: peer.evaluated ? skPrimary : skSurfaceAlt,
                border: Border.all(
                  color: peer.evaluated ? skPrimary : skBorder,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: peer.evaluated
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : Text(
                      peer.initials,
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: skTextMid,
                      ),
                    ),
            ),
            const SizedBox(width: 13),
            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: skText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    peer.evaluated ? 'Evaluado' : 'Pendiente',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: peer.evaluated
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color:
                          peer.evaluated ? skPrimary : skTextFaint,
                    ),
                  ),
                ],
              ),
            ),
            if (!peer.evaluated)
              const Icon(Icons.chevron_right_rounded,
                  size: 14, color: skTextFaint),
          ],
        ),
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
