import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/theme/teacher_colors.dart';

// controllers
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';

// models
import 'package:example/presentation/models/csv_import_summary.dart';

// widgets
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_category_card.dart';


import 'package:example/presentation/pages/teacher/widgets/import/t_import_header.dart';
import 'package:example/presentation/pages/teacher/widgets/import/t_import_empty_state.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_import_button.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_import_progress.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_import_error.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_section_label.dart';

class TImportPage extends StatelessWidget {
  const TImportPage({super.key});

  // ─────────────────────────────────────────────────────────────────────────────
  // 📂 CSV FLOW
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _pickAndImport(
    BuildContext context,
    TeacherCourseImportController ctrl,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: false,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final content = await File(path).readAsString();

    if (!context.mounted) return;

    final courseId = await _showCoursePicker(context, ctrl);
    if (courseId == null) return;

    await ctrl.importCsvFromFilename(content, file.name, courseId);

    if (!context.mounted) return;

    final summary = ctrl.lastImportSummary.value;
    if (summary == null) return;

    await _showImportSummaryDialog(context, summary);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Importación lista: ${summary.studentsCreated} estudiantes y ${summary.groupsCreated} grupos creados.',
          style: GoogleFonts.sora(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: tkSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📊 RESULT DIALOG
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _showImportSummaryDialog(
    BuildContext context,
    CsvImportSummary summary,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: tkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: tkGold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: tkGold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Importación completada',
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tkText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary.categoryName,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se crearon ${summary.studentsCreated} estudiantes y ${summary.groupsCreated} grupos.',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tkTextMid,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: tkGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Entendido',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: tkBackground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 📚 COURSE PICKER
  // ─────────────────────────────────────────────────────────────────────────────

  Future<int?> _showCoursePicker(
    BuildContext context,
    TeacherCourseImportController ctrl,
  ) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CoursePickerSheet(ctrl: ctrl),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 🧱 UI
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = Get.find<TeacherSessionController>();
    final courseCtrl = Get.find<TeacherCourseImportController>();

    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────────────────────────
            Obx(() {
              final t = sessionCtrl.teacher.value;
              if (t == null) return const SizedBox.shrink();

              return TImportHeader(
                teacher: t,
                onCoursesTap: () => Get.toNamed('/teacher/courses'),
              );
            }),

            const Divider(height: 1, color: tkBorder),

            // ── BODY ───────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🚀 Import button
                    Obx(() => TeacherImportButton(
                          loading: courseCtrl.importLoading.value,
                          onTap: () =>
                              _pickAndImport(context, courseCtrl),
                        )),

                    /// ⏳ Progress
                    Obx(() => TeacherImportProgress(
                          status: courseCtrl.importLoading.value
                              ? courseCtrl.importProgress.value
                              : '',
                        )),

                    /// ❌ Error
                    Obx(() => TeacherImportError(
                          message: courseCtrl.importError.value,
                        )),

                    const SizedBox(height: 18),

                    /// 📂 Section title
                    const TeacherSectionLabel(
                      'CATEGORÍAS IMPORTADAS',
                    ),

                    const SizedBox(height: 10),

                    /// 📋 Categories
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

            // ── BOTTOM NAV ─────────────────────────────────────────
            const TeacherBottomNav(activeIndex: 3),
          ],
        ),
      ),
    );
  }
}

class _CoursePickerSheet extends StatefulWidget {
  final TeacherCourseImportController ctrl;

  const _CoursePickerSheet({required this.ctrl});

  @override
  State<_CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends State<_CoursePickerSheet> {
  bool _creating = false;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asignar a curso',
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: tkText,
            ),
          ),
          const SizedBox(height: 16),

          /// 📋 cursos
          Obx(() {
            final courses = ctrl.courses;

            return Column(
              children: courses
                  .map(
                    (c) => GestureDetector(
                      onTap: () => Navigator.pop(context, c.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: tkSurfaceAlt,
                          border: Border.all(color: tkBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 16,
                              color: tkGold,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.name,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: tkText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),

          const SizedBox(height: 12),

          /// ➕ crear nuevo
          if (_creating) ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Nombre del curso',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                hintText: 'Código (opcional)',
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: () async {
                final name = _nameCtrl.text.trim();
                if (name.isEmpty) return;

                final ok = await ctrl.createCourse(
                  name,
                  _codeCtrl.text.trim(),
                );

                if (ok && mounted) {
                  Navigator.pop(context, ctrl.courses.first.id);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: tkGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Crear y seleccionar',
                  style: GoogleFonts.sora(
                    color: tkBackground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => setState(() => _creating = true),
              child: Text(
                '+ Crear nuevo curso',
                style: GoogleFonts.sora(color: tkGold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}