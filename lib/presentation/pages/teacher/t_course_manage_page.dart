import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';

class TCourseManagePage extends StatelessWidget {
  const TCourseManagePage({super.key});

  void _showCreateSheet(BuildContext context, TeacherCourseImportController ctrl) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                20,
                22,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nuevo curso',
                    style: GoogleFonts.sora(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: tkText,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel('Nombre'),
                  const SizedBox(height: 6),
                  _SheetTextField(
                    controller: nameCtrl,
                    hint: 'Ej: Estructuras de Datos',
                  ),
                  const SizedBox(height: 14),
                  _FieldLabel('Código (opcional)'),
                  const SizedBox(height: 6),
                  _SheetTextField(controller: codeCtrl, hint: 'Ej: DM2026-10'),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => GestureDetector(
                        onTap: ctrl.courseCreateLoading.value
                            ? null
                            : () async {
                                final name = nameCtrl.text.trim();
                                if (name.isEmpty) return;

                                final ok = await ctrl.createCourse(
                                  name,
                                  codeCtrl.text.trim(),
                                );
                                if (!ok) {
                                  Get.snackbar(
                                    'No se pudo crear',
                                    ctrl.courseCreateError.value,
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: ctrl.courseCreateLoading.value
                                ? tkGold.withValues(alpha: 0.45)
                                : tkGold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: ctrl.courseCreateLoading.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: tkBackground,
                                  ),
                                )
                              : Text(
                                  'Crear curso',
                                  style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: tkBackground,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    TeacherCourseImportController ctrl,
    CourseModel course,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar curso',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: tkText,
          ),
        ),
        content: Text(
          '¿Eliminar "${course.name}"? Las categorías asociadas quedarán sin curso asignado.',
          style: GoogleFonts.sora(fontSize: 13, color: tkTextMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: GoogleFonts.sora(color: tkTextFaint, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctrl.deleteCourse(course.id);
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.sora(
                color: tkDanger,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherCourseImportController>();
    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: tkSurface,
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TeacherBackButton(label: 'Volver', route: '/teacher/dash'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis cursos',
                              style: GoogleFonts.sora(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: tkText,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Organiza tus evaluaciones por curso',
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: tkTextFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showCreateSheet(context, ctrl),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: tkGold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: tkBackground,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Nuevo',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
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
                ],
              ),
            ),
            const Divider(height: 1, color: tkBorder),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.courseLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: tkGold),
                  );
                }
                final courses = ctrl.courses;
                if (courses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 36,
                            color: tkTextFaint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sin cursos creados',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tkTextFaint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Toca "Nuevo" para añadir tu primer curso',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: tkTextFaint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(22),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final course = courses[i];
                    return _CourseCard(
                      course: course,
                      onDelete: () => _confirmDelete(context, ctrl, course),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Course card ────────────────────────────────────────────────────────────────

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onDelete;
  const _CourseCard({required this.course, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tkGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.school_rounded, size: 20, color: tkGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tkText,
                  ),
                ),
                if (course.code.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    course.code,
                    style: GoogleFonts.dmMono(fontSize: 11, color: tkTextFaint),
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: tkDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: tkDanger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet helpers ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: tkTextFaint,
        letterSpacing: 1,
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _SheetTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.sora(fontSize: 14, color: tkText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(fontSize: 14, color: tkTextFaint),
        filled: true,
        fillColor: tkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tkGold),
        ),
      ),
    );
  }
}
