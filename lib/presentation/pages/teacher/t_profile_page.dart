import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher_controller.dart';
import 'package:example/domain/models/group_category.dart';

class TProfilePage extends StatelessWidget {
  const TProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    //:v
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
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Obx(() {
                final t = ctrl.teacher.value;
                if (t == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [tkGold, Color(0xFFE3C26E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(t.initials,
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
                          Text(t.name,
                              style: GoogleFonts.sora(
                                fontSize: 17, fontWeight: FontWeight.w800,
                                letterSpacing: -0.3, color: tkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(t.email,
                              style: GoogleFonts.dmMono(
                                  fontSize: 11, color: tkTextFaint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ctrl.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: tkDanger.withValues(alpha: 0.1),
                          border: Border.all(
                              color: tkDanger.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 13, color: tkDanger),
                            const SizedBox(width: 6),
                            Text('Salir',
                                style: GoogleFonts.sora(
                                  fontSize: 12, fontWeight: FontWeight.w700,
                                  color: tkDanger,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 1, color: tkBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section label
                    Text('GRUPOS',
                        style: GoogleFonts.sora(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: tkTextFaint, letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 10),

                    // Import button
                    Obx(() {
                      final loading = ctrl.importLoading.value;
                      return GestureDetector(
                        onTap: loading ? null : () => Get.offNamed('/teacher/import'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: loading ? tkSurfaceAlt : tkGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      color: tkBackground, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.upload_file_rounded,
                                        size: 15, color: tkBackground),
                                    const SizedBox(width: 8),
                                    Text('Importar CSV',
                                        style: GoogleFonts.sora(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: tkBackground,
                                        )),
                                  ],
                                ),
                        ),
                      );
                    }),

                    // Error message
                    Obx(() {
                      final err = ctrl.importError.value;
                      if (err.isEmpty) return const SizedBox(height: 14);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(err,
                            style: GoogleFonts.sora(
                                fontSize: 12, color: tkDanger)),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Category list or empty state
                    Obx(() {
                      final cats = ctrl.categories;
                      if (cats.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            color: tkSurface,
                            border: Border.all(color: tkBorder),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.folder_open_rounded,
                                  size: 32, color: tkTextFaint),
                              const SizedBox(height: 10),
                              Text('Sin categorías importadas',
                                  style: GoogleFonts.sora(
                                    fontSize: 13, color: tkTextFaint,
                                    fontWeight: FontWeight.w600,
                                  )),
                              const SizedBox(height: 4),
                              Text('Usa el botón de arriba para cargar un CSV',
                                  style: GoogleFonts.sora(
                                      fontSize: 11, color: tkTextFaint)),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: cats
                            .map((c) => _CategoryCard(
                                  category: c,
                                  onDelete: () => ctrl.deleteCategory(c.id),
                                ))
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            _TBottomNav(activeIndex: 3),
          ],
        ),
      ),
    );
  }
}

// ── Category card ──────────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final GroupCategory category;
  final VoidCallback  onDelete;
  const _CategoryCard({required this.category, required this.onDelete});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat  = widget.category;
    final date = '${cat.importedAt.day}/${cat.importedAt.month}/${cat.importedAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18, color: tkTextMid,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat.name,
                            style: GoogleFonts.sora(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: tkText,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          '${cat.groupCount} grupos · ${cat.studentCount} estudiantes · $date',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: tkTextFaint),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: tkDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: tkDanger),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, color: tkBorder),
            ...cat.groups.map((g) => _GroupRow(group: g)),
          ],
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final CourseGroup group;
  const _GroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 14, color: tkGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(group.name,
                    style: GoogleFonts.sora(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: tkText,
                    )),
              ),
              const SizedBox(width: 8),
              Text('${group.members.length} estudiantes',
                  style: GoogleFonts.dmMono(
                      fontSize: 10, color: tkTextFaint)),
            ],
          ),
          const SizedBox(height: 6),
          ...group.members.map((m) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 3),
                child: Text(
                  _toTitleCase(m.name),
                  style: GoogleFonts.sora(fontSize: 11, color: tkTextMid),
                ),
              )),
        ],
      ),
    );
  }

  String _toTitleCase(String s) => s
      .split(' ')
      .map((w) =>
          w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

// ── Bottom nav (shared) ────────────────────────────────────────────────────────

class _TBottomNav extends StatelessWidget {
  final int activeIndex;
  const _TBottomNav({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded,           label: 'INICIO',  route: '/teacher/dash'),
      _NavItem(icon: Icons.rate_review_rounded,    label: 'EVALUAR', route: '/teacher/new-eval'),
      _NavItem(icon: Icons.bar_chart_rounded,      label: 'DATOS',   route: '/teacher/results'),
      _NavItem(icon: Icons.upload_file_rounded,     label: 'IMPORTAR', route: '/teacher/profile'),
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
                if (!Get.currentRoute.endsWith(e.value.route)) {
                  Get.offNamed(e.value.route);
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
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}
