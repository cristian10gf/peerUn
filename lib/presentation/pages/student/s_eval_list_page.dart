import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/domain/models/evaluation.dart';
// EvalStudentStatus lives in student_controller.dart

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
                          const Icon(Icons.history_rounded,
                              size: 40, color: skTextFaint),
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
                                fontSize: 12, color: skTextFaint),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(22),
                  itemCount: evals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _HistorialItem(eval: evals[i], ctrl: ctrl),
                );
              }),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            _BottomNav(activeIndex: 1),
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
      final status = ctrl.evalStatuses[eval.id];

      final (badgeLabel, badgeColor, badgeBg) = switch (status) {
        EvalStudentStatus.activePending   => ('ACTIVA', skPrimary, skPrimaryLight),
        EvalStudentStatus.activeCompleted => ('ACTIVA · REALIZADA', critGreen, const Color(0xFFD1FAE5)),
        EvalStudentStatus.closedNotDone   => ('FINALIZADA · NO REALIZADA', const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
        EvalStudentStatus.closedCompleted => ('FINALIZADA', skTextFaint, skSurfaceAlt),
        null                              => eval.isActive
            ? ('ACTIVA', skPrimary, skPrimaryLight)
            : ('CERRADA', skTextFaint, skSurfaceAlt),
      };

      final showEvaluarBtn = status == EvalStudentStatus.activePending;
      final borderColor = switch (status) {
        EvalStudentStatus.activePending   => skPrimaryMid,
        EvalStudentStatus.activeCompleted => critGreen,
        EvalStudentStatus.closedNotDone   => const Color(0xFFFECACA),
        _                                 => skBorder,
      };

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
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeLabel,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
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

// ── Bottom nav ─────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int activeIndex;
  const _BottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded,          label: 'Inicio',    route: '/student/courses'),
      _NavItem(icon: Icons.history_rounded,        label: 'Historial', route: '/student/eval-list'),
      _NavItem(icon: Icons.bar_chart_rounded,      label: 'Resultados',route: '/student/results'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Perfil',    route: null),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: skSurface,
        border: Border(top: BorderSide(color: skBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == activeIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (e.value.route != null &&
                    !Get.currentRoute.endsWith(e.value.route!)) {
                  Get.offNamed(e.value.route!);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(e.value.icon, size: 20,
                      color: isActive ? skPrimary : skTextFaint),
                  const SizedBox(height: 3),
                  Text(
                    e.value.label,
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      letterSpacing: 0.3,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? skPrimary : skTextFaint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? route;
  const _NavItem({required this.icon, required this.label, this.route});
}
