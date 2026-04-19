import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_dash_header.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_dash_stats_row.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_active_eval_card.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_eval_card.dart';

import 'package:google_fonts/google_fonts.dart';

class TDashPage extends StatelessWidget {
  const TDashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = Get.find<TeacherSessionController>();
    final courseCtrl = Get.find<TeacherCourseImportController>();
    final evalCtrl = Get.find<TeacherEvaluationController>();
    final resultsCtrl = Get.find<TeacherResultsController>();

    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            TDashHeader(
              onProfileTap: () => _showProfileSheet(context, sessionCtrl),
            ),

            const Divider(height: 1, color: tkBorder),

            // ── Body ───────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: tkGold,
                onRefresh: () async {
                  await Future.wait([
                    evalCtrl.refreshData(),
                    courseCtrl.refreshData(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats ──────────────────────────────────────
                    Obx(() => TDashStatsRow(
                          categories:
                              courseCtrl.categories.length.toString(),
                          active: evalCtrl.evaluations
                              .where((e) => e.isActive)
                              .length
                              .toString(),
                          groups: courseCtrl.totalGroups.toString(),
                        )),

                    const SizedBox(height: 20),

                    // ── Active evaluation ──────────────────────────
                    Obx(() {
                      final eval = evalCtrl.activeEval.value;
                      if (eval == null) return const SizedBox.shrink();

                      return Column(
                        children: [
                          TActiveEvalCard(
                            eval: eval,
                            resultsCtrl: resultsCtrl,
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    // ── Section header ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MIS EVALUACIONES',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tkTextFaint,
                            letterSpacing: 1.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.toNamed('/teacher/new-eval'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: tkGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 14,
                                  color: tkBackground,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nueva',
                                  style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: tkBackground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Evaluations list ───────────────────────────
                    Obx(() {
                      if (evalCtrl.evaluations.isEmpty) {
                        return _EmptyState();
                      }

                      return Column(
                        children: evalCtrl.evaluations
                            .map(
                              (e) => TEvalCard(
                                eval: e,
                                resultsCtrl: resultsCtrl,
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
                ),
              ),
            ),

            // ── Bottom navigation ─────────────────────────────────
            const TeacherBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }

  // ── Profile modal ───────────────────────────────────────────────

  void _showProfileSheet(
    BuildContext context,
    TeacherSessionController sessionCtrl,
  ) {
    final teacher = sessionCtrl.teacher.value;
    if (teacher == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: tkBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),

            // Info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [tkGold, Color(0xFFE3C26E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    teacher.initials,
                    style: GoogleFonts.dmMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: tkBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        teacher.email,
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: tkTextFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: tkBorder),

            const SizedBox(height: 12),

            // Logout
            GestureDetector(
              onTap: () {
                Get.back();
                sessionCtrl.logout();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: tkDanger.withValues(alpha: 0.1),
                  border: Border.all(color: tkDanger.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, size: 16, color: tkDanger),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tkDanger,
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

// ── Empty state ───────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 32,
            color: tkTextFaint,
          ),
          const SizedBox(height: 10),
          Text(
            'Sin evaluaciones aún',
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tkTextMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Importa grupos y crea tu primera evaluación',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: tkTextFaint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}