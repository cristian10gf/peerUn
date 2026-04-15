import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/student_home.dart';
import 'package:example/presentation/pages/student/widgets/student_bottom_nav.dart';
import 'package:example/presentation/pages/student/widgets/student_course_header.dart';
import 'package:example/presentation/pages/student/widgets/student_profile_sheet.dart';

class SCoursesPage extends StatelessWidget {
  const SCoursesPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis evaluaciones',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: skTextFaint,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Obx(() {
                          final s = ctrl.student.value;
                          if (s == null) return const SizedBox.shrink();
                          return Text(
                            s.name,
                            style: GoogleFonts.sora(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: skText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Obx(() {
                    final s = ctrl.student.value;
                    if (s == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => StudentProfileSheet.show(context, ctrl),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: skPrimaryLight,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            s.initials,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: skPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1, color: skBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: skPrimary,
                onRefresh: () => ctrl.refreshData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      'MIS CURSOS',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      if (ctrl.isLoadingHome.value) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 22,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: skSurface,
                            border: Border.all(color: skBorder),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: skPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Cargando cursos matriculados...',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  color: skTextMid,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (ctrl.homeLoadError.value.isNotEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFFECACA)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            ctrl.homeLoadError.value,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        );
                      }

                      if (ctrl.homeCourses.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: skSurfaceAlt,
                            border: Border.all(color: skBorder),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Aún no tienes cursos matriculados visibles.',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              color: skTextMid,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: ctrl.homeCourses
                            .map((course) => _StudentCourseCard(course: course, ctrl: ctrl))
                            .toList(),
                      );
                    }),
                    const SizedBox(height: 20),

                    // ── Destacado: evaluación pendiente más reciente ───────
                    Obx(() {
                      final pending = ctrl.pendingEvaluationsSorted;
                      if (pending.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _ActiveEvalCard(eval: pending.first, ctrl: ctrl),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    Text(
                      'EVALUACIONES ACTIVAS',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      final active = ctrl.activeEvaluations;
                      if (active.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: skSurfaceAlt,
                            border: Border.all(color: skBorder),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.rate_review_outlined,
                                size: 32,
                                color: skTextFaint,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sin evaluaciones activas',
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: skTextMid,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aquí aparecerán las evaluaciones\ncuando el docente las active',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: skTextFaint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      final grouped = ctrl.groupedActiveEvaluationsByCourse;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: grouped.entries
                            .expand(
                              (entry) => [
                                if (grouped.length > 1) ...[
                                  StudentCourseHeader(name: entry.key),
                                  const SizedBox(height: 8),
                                ],
                                ...entry.value.map(
                                  (e) => _EvalCard(eval: e, ctrl: ctrl),
                                ),
                              ],
                            )
                            .toList(),
                      );
                    }),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            StudentBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }
}

// ── Course header ──────────────────────────────────────────────────────────────

class _StudentCourseCard extends StatelessWidget {
  final StudentHomeCourse course;
  final StudentController ctrl;

  const _StudentCourseCard({required this.course, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expanded = ctrl.isCourseExpanded(course.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: skSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: course.hasGroupAssignment ? skBorderMid : const Color(0xFFFECACA),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => ctrl.toggleCourseExpanded(course.id),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name.isEmpty ? 'Curso sin nombre' : course.name,
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: skText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            course.hasGroupAssignment
                                ? '${course.categories.length} categorias con grupo'
                                : 'Sin grupo asignado',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: skTextMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: course.hasGroupAssignment
                            ? skPrimaryLight
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        course.hasGroupAssignment ? 'Con grupo' : 'Sin grupo',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: course.hasGroupAssignment
                              ? skPrimary
                              : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: skTextMid,
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    const Divider(height: 1, color: skBorder),
                    const SizedBox(height: 10),
                    if (course.categories.isEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Este curso aún no tiene categorías con grupo para ti.',
                          style: GoogleFonts.sora(
                            fontSize: 11,
                            color: skTextMid,
                          ),
                        ),
                      )
                    else
                      ...course.categories.map(
                        (category) => _StudentCategoryCard(
                          category: category,
                          ctrl: ctrl,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _StudentCategoryCard extends StatelessWidget {
  final StudentHomeCategory category;
  final StudentController ctrl;

  const _StudentCategoryCard({required this.category, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final group = category.group;
    if (group == null) return const SizedBox.shrink();

    return Obx(() {
      final expanded = ctrl.isCategoryExpanded(category.id);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: skSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: skBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: skText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ctrl.toggleCategoryExpanded(category.id),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(42, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    expanded ? 'Ocultar' : 'Ver',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: skPrimary,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              group.name,
              style: GoogleFonts.dmMono(fontSize: 11, color: skTextMid),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: group.members
                  .take(3)
                  .map(
                    (member) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: skSurface,
                        border: Border.all(color: skBorder),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        member.name,
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          color: skText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (group.members.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${group.members.length - 3} integrantes',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    color: skTextMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (expanded) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.members
                    .skip(3)
                    .map(
                      (member) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: skSurface,
                          border: Border.all(color: skBorder),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          member.name,
                          style: GoogleFonts.sora(
                            fontSize: 10,
                            color: skText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Active eval hero card ───────────────────────────────────────────────────────

class _ActiveEvalCard extends StatelessWidget {
  final Evaluation eval;
  final StudentController ctrl;
  const _ActiveEvalCard({required this.eval, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final closesIn = eval.closesAt.difference(DateTime.now());
    final timeLabel = _fmtDuration(closesIn);

    return GestureDetector(
      onTap: () async {
        await ctrl.selectEvalForEvaluation(eval);
        Get.toNamed('/student/peers');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: skPrimary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PulseDot(color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'EVALUACIÓN PENDIENTE',
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eval.name,
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${eval.categoryName} · $timeLabel',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Progreso',
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '${ctrl.doneCount}/${ctrl.totalPeers}',
                        style: GoogleFonts.dmMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(
              () => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: ctrl.evalProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'Evaluar ahora',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0) return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }
}

// ── Eval card ──────────────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  final Evaluation eval;
  final StudentController ctrl;
  const _EvalCard({required this.eval, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final closesIn = eval.closesAt.difference(DateTime.now());
    final timeLabel = _fmt(closesIn);

    return Obx(() {
      final isPending = ctrl.canEvaluate(eval);
      final badge = ctrl.statusBadgeInfoFor(eval);
      final borderColor = ctrl.statusBorderColorFor(eval);

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skSurface,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge
            Row(
              children: [
                if (isPending) ...[
                  _PulseDot(),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(Icons.check_circle_rounded, size: 12, color: critGreen),
                  const SizedBox(width: 5),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badge.backgroundColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge.label,
                    style: GoogleFonts.sora(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badge.textColor,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              eval.name,
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: skText,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${eval.categoryName} · $timeLabel',
              style: GoogleFonts.dmMono(fontSize: 11, color: skTextFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (isPending) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await ctrl.selectEvalForEvaluation(eval);
                        Get.toNamed('/student/peers');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  String _fmt(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0) return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({this.color = skPrimary});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────
