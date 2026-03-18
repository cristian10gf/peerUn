import 'package:example/domain/models/evaluation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher_controller.dart';
import 'package:example/domain/models/teacher_data.dart';

class TDashPage extends StatelessWidget {
  const TDashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherController>();
    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: tkSurface,
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Panel docente',
                                style: GoogleFonts.sora(
                                  fontSize: 12, color: tkTextFaint,
                                  letterSpacing: 0.5, fontWeight: FontWeight.w500,
                                )),
                            Obx(() {
                              final t = ctrl.teacher.value;
                              if (t == null) return const SizedBox.shrink();
                              return Text(t.name,
                                  style: GoogleFonts.sora(
                                    fontSize: 22, fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5, color: tkText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis);
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        final t = ctrl.teacher.value;
                        if (t == null) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => _showProfileSheet(context, ctrl),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [tkGold, Color(0xFFE3C26E)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(t.initials,
                                  style: GoogleFonts.dmMono(
                                    fontSize: 11, fontWeight: FontWeight.w800,
                                    color: tkBackground,
                                  )),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats row — real data
                  Obx(() => Row(
                        children: [
                          _StatCard(
                            value: ctrl.categories.length.toString(),
                            label: 'CATEGORÍAS',
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            value: ctrl.evaluations
                                .where((e) => e.isActive)
                                .length
                                .toString(),
                            label: 'ACTIVAS',
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            value: ctrl.totalGroups.toString(),
                            label: 'GRUPOS',
                          ),
                        ],
                      )),
                ],
              ),
            ),
            const Divider(height: 1, color: tkBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active eval card (only when there is one)
                    Obx(() {
                      final eval = ctrl.activeEval.value;
                      if (eval == null) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _ActiveEvalCard(eval: eval, ctrl: ctrl),
                          const SizedBox(height: 20),
                        ],
                      );
                    }),

                    // Evaluations section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('MIS EVALUACIONES',
                            style: GoogleFonts.sora(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: tkTextFaint, letterSpacing: 1.5,
                            )),
                        GestureDetector(
                          onTap: () => Get.toNamed('/teacher/new-eval'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: tkGold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded,
                                    size: 13, color: tkBackground),
                                const SizedBox(width: 4),
                                Text('Nueva',
                                    style: GoogleFonts.sora(
                                      fontSize: 11, fontWeight: FontWeight.w700,
                                      color: tkBackground,
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Obx(() {
                      if (ctrl.evaluations.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            color: tkSurface,
                            border: Border.all(color: tkBorder),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.rate_review_outlined,
                                  size: 32, color: tkTextFaint),
                              const SizedBox(height: 10),
                              Text('Sin evaluaciones aún',
                                  style: GoogleFonts.sora(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: tkTextMid,
                                  )),
                              const SizedBox(height: 4),
                              Text('Importa grupos y crea tu primera evaluación',
                                  style: GoogleFonts.sora(
                                      fontSize: 11, color: tkTextFaint)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: ctrl.evaluations
                            .map((e) => _EvalCard(eval: e, ctrl: ctrl))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            _TBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, TeacherController ctrl) {
    final teacher = ctrl.currentTeacher;
    showModalBottomSheet(
      context: context,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: tkBorder,
                  borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [tkGold, Color(0xFFE3C26E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(teacher.initials,
                      style: GoogleFonts.dmMono(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: tkBackground,
                      )),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(teacher.name,
                          style: GoogleFonts.sora(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: tkText,
                          )),
                      const SizedBox(height: 2),
                      Text(teacher.email,
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: tkTextFaint)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: tkBorder, height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Get.back();
                ctrl.logout();
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
                    Icon(Icons.logout_rounded, size: 16, color: tkDanger),
                    const SizedBox(width: 8),
                    Text('Cerrar sesión',
                        style: GoogleFonts.sora(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: tkDanger,
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

// ── Active eval card (pulsing, real data) ──────────────────────────────────────

class _ActiveEvalCard extends StatefulWidget {
  final Evaluation eval;
  final TeacherController ctrl;
  const _ActiveEvalCard({required this.eval, required this.ctrl});

  @override
  State<_ActiveEvalCard> createState() => _ActiveEvalCardState();
}

class _ActiveEvalCardState extends State<_ActiveEvalCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.35)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eval      = widget.eval;
    final closesIn  = eval.closesAt.difference(DateTime.now());
    final closesLabel = _formatDuration(closesIn);

    return GestureDetector(
      onTap: () async {
        await widget.ctrl.loadGroupResults(eval);
        Get.toNamed('/teacher/results');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tkGoldLight,
          border: Border.all(color: tkGoldBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Opacity(
                    opacity: _anim.value,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                          color: tkGold, shape: BoxShape.circle),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('EN CURSO',
                    style: GoogleFonts.sora(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: tkGold, letterSpacing: 1.5,
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eval.name,
                          style: GoogleFonts.sora(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: tkText,
                          )),
                      const SizedBox(height: 3),
                      Text('${eval.categoryName} · $closesLabel',
                          style: GoogleFonts.dmMono(
                              fontSize: 9, color: tkTextFaint),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Activa',
                        style: GoogleFonts.dmMono(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: tkGold,
                        )),
                    Text('ver resultados',
                        style: GoogleFonts.sora(
                            fontSize: 8, color: tkTextFaint)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0)  return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }
}

// ── Evaluation card ────────────────────────────────────────────────────────────

class _EvalCard extends StatelessWidget {
  final Evaluation eval;
  final TeacherController ctrl;
  const _EvalCard({required this.eval, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isActive = eval.isActive;
    final closesIn = eval.closesAt.difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(eval.name,
                    style: GoogleFonts.sora(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: tkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? tkSuccess.withValues(alpha: 0.12)
                      : tkSurfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'ACTIVA' : 'CERRADA',
                  style: GoogleFonts.sora(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: isActive ? tkSuccess : tkTextFaint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${eval.categoryName} · ${eval.hours}h · '
            '${eval.visibility == 'public' ? 'Pública' : 'Privada'}'
            '${isActive ? ' · ${_fmt(closesIn)}' : ''}',
            style: GoogleFonts.dmMono(fontSize: 11, color: tkTextFaint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CourseBtn(
                icon: Icons.group_outlined,
                label: 'Grupos',
                onTap: () => Get.toNamed('/teacher/import'),
              ),
              const SizedBox(width: 6),
              _CourseBtn(
                icon: Icons.bar_chart_rounded,
                label: 'Resultados',
                gold: true,
                onTap: () async {
                  await ctrl.loadGroupResults(eval);
                  Get.toNamed('/teacher/results');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0)  return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: tkSurfaceAlt,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.dmMono(
                  fontSize: 20, fontWeight: FontWeight.w800, color: tkText,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.sora(
                  fontSize: 10, fontWeight: FontWeight.w600,
                  color: tkTextFaint, letterSpacing: 0.5,
                )),
          ],
        ),
      ),
    );
  }
}

class _CourseBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool gold;
  final VoidCallback onTap;

  const _CourseBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: gold ? tkGold : tkSurfaceAlt,
            border: Border.all(color: gold ? tkGold : tkBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: gold ? tkBackground : tkTextMid),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      style: GoogleFonts.sora(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: gold ? tkBackground : tkTextMid,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TBottomNav extends StatelessWidget {
  final int activeIndex;
  const _TBottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded,          label: 'INICIO',   route: '/teacher/dash'),
      _NavItem(icon: Icons.rate_review_rounded,   label: 'EVALUAR',  route: '/teacher/new-eval'),
      _NavItem(icon: Icons.bar_chart_rounded,     label: 'DATOS',    route: '/teacher/results'),
      _NavItem(icon: Icons.person_outline_rounded, label: 'PERFIL',  route: null),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: tkSurface,
        border: Border(top: BorderSide(color: tkBorder)),
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
                  Icon(e.value.icon, size: 18,
                      color: isActive ? tkGold : tkTextFaint),
                  const SizedBox(height: 3),
                  Text(e.value.label,
                      style: GoogleFonts.sora(
                        fontSize: 9, letterSpacing: 0.3,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? tkGold : tkTextFaint,
                      )),
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
