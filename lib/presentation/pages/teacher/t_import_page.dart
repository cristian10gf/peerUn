import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';
import 'package:example/domain/models/group_category.dart';

class TImportPage extends StatelessWidget {
  const TImportPage({super.key});

  Future<void> _pickAndImport(TeacherController ctrl) async {
    final result = await FilePicker.platform.pickFiles(
      type:              FileType.custom,
      allowedExtensions: ['csv'],
      withData:          false,
      withReadStream:    false,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final content      = await File(path).readAsString();
    final rawName      = file.name.replaceAll(RegExp(r'\.csv$', caseSensitive: false), '');
    // Strip trailing Brightspace timestamp pattern e.g. _20260217225843
    final categoryName = rawName.replaceAll(RegExp(r'_\d{14}'), '');

    await ctrl.importCsv(content, categoryName);
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
                  Text('Desde archivo CSV de Brightspace',
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
                    // Import button
                    Obx(() {
                      final loading = ctrl.importLoading.value;
                      return GestureDetector(
                        onTap: loading ? null : () => _pickAndImport(ctrl),
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
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: tkBackground, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.upload_file_rounded,
                                        size: 16, color: tkBackground),
                                    const SizedBox(width: 8),
                                    Text('Importar CSV',
                                        style: GoogleFonts.sora(
                                          fontSize: 14,
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
                      if (err.isEmpty) return const SizedBox(height: 16);
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(err,
                            style: GoogleFonts.sora(
                                fontSize: 12, color: tkDanger)),
                      );
                    }),

                    const SizedBox(height: 18),

                    // Section label
                    Text('CATEGORÍAS IMPORTADAS',
                        style: GoogleFonts.sora(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: tkTextFaint, letterSpacing: 1.5,
                        )),
                    const SizedBox(height: 10),

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

          // Expandable group list
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
                  style: GoogleFonts.sora(
                      fontSize: 11, color: tkTextMid),
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

// ── Back button ────────────────────────────────────────────────────────────────

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
