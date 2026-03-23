import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_category_card.dart';

class TImportPage extends StatelessWidget {
  const TImportPage({super.key});

  Future<void> _pickAndImport(
    BuildContext context,
    TeacherController ctrl,
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
    final rawName = file.name.replaceAll(
      RegExp(r'\.csv$', caseSensitive: false),
      '',
    );
    // Strip trailing Brightspace timestamp pattern e.g. _20260217225843
    final categoryName = rawName.replaceAll(RegExp(r'_\d{14}'), '');

    if (!context.mounted) return;
    final courseId = await _showCoursePicker(context, ctrl);
    if (courseId == null) return; // user cancelled

    await ctrl.importCsv(content, categoryName, courseId);

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

  Future<void> _showImportSummaryDialog(
    BuildContext context,
    CsvImportSummary summary,
  ) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: tkSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  /// Shows a bottom sheet to pick (or quick-create) a course.
  /// Returns the selected courseId (0 = sin curso), or null if cancelled.
  Future<int?> _showCoursePicker(
    BuildContext context,
    TeacherController ctrl,
  ) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CoursePickerSheet(ctrl: ctrl),
    );
  }

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
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Obx(() {
                final t = ctrl.teacher.value;
                if (t == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          onTap: () => Get.toNamed('/teacher/courses'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: tkGold.withValues(alpha: 0.1),
                              border: Border.all(
                                color: tkGold.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 13,
                                  color: tkGold,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cursos',
                                  style: GoogleFonts.sora(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tkGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Importar grupos',
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: tkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Desde archivo CSV de Brightspace',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: tkTextFaint,
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
                    // Import button
                    Obx(() {
                      final loading = ctrl.importLoading.value;
                      return GestureDetector(
                        onTap: loading
                            ? null
                            : () => _pickAndImport(context, ctrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: loading ? tkSurfaceAlt : tkGold,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
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
                                      size: 16,
                                      color: tkBackground,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Importar CSV',
                                      style: GoogleFonts.sora(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: tkBackground,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    }),

                    Obx(() {
                      final loading = ctrl.importLoading.value;
                      final status = ctrl.importProgress.value;
                      if (!loading || status.isEmpty) {
                        return const SizedBox(height: 12);
                      }
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: tkSurface,
                          border: Border.all(color: tkBorder),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: tkGold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status,
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tkTextMid,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Error message
                    Obx(() {
                      final err = ctrl.importError.value;
                      if (err.isEmpty) return const SizedBox(height: 6);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          err,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: tkDanger,
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Section label
                    Text(
                      'CATEGORÍAS IMPORTADAS',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tkTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),

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
            TeacherBottomNav(activeIndex: 3),
          ],
        ),
      ),
    );
  }
}

// ── Category card ──────────────────────────────────────────────────────────────

// ── Course picker sheet ────────────────────────────────────────────────────────

class _CoursePickerSheet extends StatefulWidget {
  final TeacherController ctrl;
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
          const SizedBox(height: 4),
          Text(
            'Selecciona el curso al que pertenece esta importación',
            style: GoogleFonts.sora(fontSize: 12, color: tkTextFaint),
          ),
          const SizedBox(height: 16),

          // Existing courses
          Obx(() {
            final courses = ctrl.courses;
            if (courses.isEmpty && !_creating) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'No tienes cursos. Crea uno abajo.',
                  style: GoogleFonts.sora(fontSize: 12, color: tkTextFaint),
                ),
              );
            }
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
                                c.code.isNotEmpty
                                    ? '${c.name}  ·  ${c.code}'
                                    : c.name,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: tkText,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: tkTextFaint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),

          // Quick-create form toggle
          if (_creating) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _nameCtrl,
              style: GoogleFonts.sora(fontSize: 14, color: tkText),
              decoration: InputDecoration(
                hintText: 'Nombre del curso',
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
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeCtrl,
              style: GoogleFonts.sora(fontSize: 14, color: tkText),
              decoration: InputDecoration(
                hintText: 'Código (opcional)',
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
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => GestureDetector(
                  onTap: ctrl.courseCreateLoading.value
                      ? null
                      : () async {
                          final name = _nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          final nav = Navigator.of(context);
                          final ok = await ctrl.createCourse(
                            name,
                            _codeCtrl.text.trim(),
                          );
                          if (!ok) {
                            if (!mounted) return;
                            Get.snackbar(
                              'No se pudo crear',
                              ctrl.courseCreateError.value,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }

                          final newId = ctrl.courses.isNotEmpty
                              ? ctrl.courses.first.id
                              : null;
                          if (mounted) nav.pop(newId);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
                            'Crear y seleccionar',
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
          ] else ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _creating = true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: tkGold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Crear nuevo curso',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tkGold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1, color: tkBorder),
          const SizedBox(height: 12),

          // Footer: only cancel (a course is required)
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () => Navigator.pop(context, null),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: tkSurfaceAlt,
                  border: Border.all(color: tkBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancelar importación',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tkTextMid,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom nav ─────────────────────────────────────────────────────────────────
