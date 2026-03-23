import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_category_card.dart';

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
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [tkGold, Color(0xFFE3C26E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t.initials,
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
                            t.name,
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: tkText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.email,
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: tkTextFaint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ctrl.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: tkDanger.withValues(alpha: 0.1),
                          border: Border.all(
                            color: tkDanger.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 13,
                              color: tkDanger,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Salir',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: tkDanger,
                              ),
                            ),
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
                    Text(
                      'GRUPOS',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tkTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Import button
                    Obx(() {
                      final loading = ctrl.importLoading.value;
                      return GestureDetector(
                        onTap: loading
                            ? null
                            : () => Get.offNamed('/teacher/import'),
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
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: tkBackground,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.upload_file_rounded,
                                      size: 15,
                                      color: tkBackground,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Importar CSV',
                                      style: GoogleFonts.sora(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: tkBackground,
                                      ),
                                    ),
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
                        child: Text(
                          err,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: tkDanger,
                          ),
                        ),
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
                            vertical: 32,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: tkSurface,
                            border: Border.all(color: tkBorder),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.folder_open_rounded,
                                size: 32,
                                color: tkTextFaint,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sin categorías importadas',
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  color: tkTextFaint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Usa el botón de arriba para cargar un CSV',
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: tkTextFaint,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: cats
                            .map(
                              (c) => TeacherCategoryCard(
                                category: c,
                                onDelete: () => ctrl.deleteCategory(c.id),
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom nav ─────────────────────────────────────────────────
            TeacherBottomNav(activeIndex: 3, importRoute: '/teacher/profile'),
          ],
        ),
      ),
    );
  }
}

// ── Category card ──────────────────────────────────────────────────────────────
