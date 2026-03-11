import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';

class TImportPage extends StatelessWidget {
  const TImportPage({super.key});

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
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(label: 'Volver', route: '/teacher/dash'),
                  const SizedBox(height: 16),
                  Text('Importar grupos',
                      style: GoogleFonts.sora(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5, color: tkText,
                      )),
                  const SizedBox(height: 3),
                  Text('Desde Brightspace · DM2610',
                      style: GoogleFonts.dmMono(
                          fontSize: 11, color: tkTextFaint)),
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
                    // Status banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: tkSuccess.withValues(alpha: 0.08),
                        border: Border.all(
                            color: tkSuccess.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                                color: tkSuccess, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Conectado a Brightspace · 3 categorías disponibles',
                            style: GoogleFonts.sora(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: tkSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text('CATEGORÍAS',
                        style: GoogleFonts.sora(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: tkTextFaint, letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 10),

                    // Categories
                    Obx(() => Column(
                          children: ctrl.importCategories
                              .asMap()
                              .entries
                              .map((e) => _CategoryCard(
                                    category: e.value,
                                    onTap: () => ctrl.toggleCategory(e.key),
                                  ))
                              .toList(),
                        )),
                    const SizedBox(height: 6),

                    // Info box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tkSurfaceAlt,
                        border: Border.all(color: tkBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Si hay una evaluación activa, los cambios de grupo se aplicarán al cerrarla.',
                        style: GoogleFonts.sora(
                          fontSize: 11, color: tkTextFaint,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Import button
                    Obx(() {
                      final n = ctrl.selectedCategoryCount;
                      return GestureDetector(
                        onTap: n > 0
                            ? () => Get.offNamed('/teacher/dash')
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: n > 0 ? tkGold : tkSurfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            n > 0
                                ? 'Importar $n categoría${n > 1 ? 's' : ''}'
                                : 'Selecciona una categoría',
                            style: GoogleFonts.sora(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: n > 0 ? tkBackground : tkTextFaint,
                            ),
                          ),
                        ),
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

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = category.selected as bool;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? tkGoldLight
              : tkSurface,
          border: Border.all(
              color: selected ? tkGold : tkBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: selected ? tkGold : tkSurfaceAlt,
                border: Border.all(
                    color: selected ? tkGold : tkBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Color(0xFF0E1117))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name as String,
                      style: GoogleFonts.sora(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: tkText,
                      )),
                  const SizedBox(height: 2),
                  Text(
                      '${category.groupCount} grupos · ${category.studentCount} estudiantes',
                      style: GoogleFonts.dmMono(
                          fontSize: 11, color: tkTextFaint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(category.lastSync as String,
                    style: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: (category.syncOk as bool)
                          ? tkSuccess
                          : tkDanger,
                    )),
                Text('SYNC',
                    style: GoogleFonts.sora(
                      fontSize: 9, fontWeight: FontWeight.w500,
                      color: tkTextFaint, letterSpacing: 0.5,
                    )),
              ],
            ),
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
          color: tkSurfaceAlt,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded,
                size: 14, color: tkTextMid),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.sora(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: tkTextMid,
                )),
          ],
        ),
      ),
    );
  }
}
