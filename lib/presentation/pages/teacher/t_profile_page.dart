import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_category_card.dart';
import 'package:example/presentation/pages/teacher/widgets/import/t_import_empty_state.dart';

import 'package:example/presentation/pages/teacher/widgets/teacher_profile_header.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_import_button.dart';

class TProfilePage extends StatelessWidget {
  const TProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = Get.find<TeacherSessionController>();
    final courseCtrl = Get.find<TeacherCourseImportController>();

    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────
            Obx(() {
              final t = sessionCtrl.teacher.value;
              if (t == null) return const SizedBox.shrink();

              return TeacherProfileHeader(
                teacher: t,
                onLogout: sessionCtrl.logout,
              );
            }),

            const Divider(height: 1, color: tkBorder),

            // ── Body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Label
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

                    /// Import button
                    Obx(() => TeacherImportButton(
                          loading: courseCtrl.importLoading.value,
                          onTap: () => Get.offNamed('/teacher/import'),
                        )),

                    /// Error
                    Obx(() {
                      final err = courseCtrl.importError.value;
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

                    /// Categories
                    Obx(() {
                      final cats = courseCtrl.categories;

                      if (cats.isEmpty) {
                        return const TImportEmptyState();
                      }

                      return Column(
                        children: cats
                            .map(
                              (c) => TeacherCategoryCard(
                                category: c,
                                onDelete: () =>
                                    courseCtrl.deleteCategory(c.id),
                              ),
                            )
                            .toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            /// Bottom nav
            const TeacherBottomNav(
              activeIndex: 0,
            ),
          ],
        ),
      ),
    );
  }
}