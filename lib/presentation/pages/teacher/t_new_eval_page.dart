import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/new_eval/t_new_eval_header.dart';
import 'package:example/presentation/pages/teacher/widgets/new_eval/t_new_eval_picker_sheets.dart';

class TNewEvalPage extends StatelessWidget {
  const TNewEvalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final evalCtrl = Get.find<TeacherEvaluationController>();
    final courseCtrl = Get.find<TeacherCourseImportController>();

    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            const TNewEvalHeader(),
            const Divider(height: 1, color: tkBorder),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nombre ─────────────────────────────
                    _SectionLabel('NOMBRE'),
                    const SizedBox(height: 8),
                    Obx(
                      () => _GoldTextField(
                        value: evalCtrl.evalName.value,
                        onChanged: evalCtrl.setEvalName,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Curso ─────────────────────────────
                    _SectionLabel('CURSO'),
                    const SizedBox(height: 8),
                    Obx(() {
                      final name = courseCtrl.selectedCourseName.value;
                      final empty = courseCtrl.courses.isEmpty;

                      return _SelectorCard(
                        text: empty
                            ? 'Sin cursos creados'
                            : name.isEmpty
                                ? 'Seleccionar curso'
                                : name,
                        disabled: empty,
                        onTap: empty
                            ? null
                            : () => _showCoursePicker(context, evalCtrl, courseCtrl),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Categoría ─────────────────────────
                    _SectionLabel('CATEGORÍA'),
                    const SizedBox(height: 8),
                    Obx(() {
                      final name = evalCtrl.selectedCategoryName.value;
                      final hasCourse = courseCtrl.selectedCourseId.value != null;
                      final cats = courseCtrl.categoriesForCourse;

                      final disabled = !hasCourse || cats.isEmpty;

                      return _SelectorCard(
                        text: !hasCourse
                            ? 'Selecciona un curso primero'
                            : cats.isEmpty
                                ? 'Sin categorías disponibles'
                                : name.isEmpty
                                    ? 'Seleccionar categoría'
                                    : name,
                        disabled: disabled,
                        onTap: disabled
                            ? null
                            : () => _showCategoryPicker(context, evalCtrl, courseCtrl),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ── Tiempo ────────────────────────────
                    _SectionLabel('DURACIÓN'),
                    const SizedBox(height: 10),
                    Obx(
                      () => Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [24, 48, 72, 168].map((h) {
                          final selected = evalCtrl.selectedHours.value == h;

                          return GestureDetector(
                            onTap: () => evalCtrl.setSelectedHours(h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected ? tkGold : tkSurfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? tkGold : tkBorder,
                                ),
                              ),
                              child: Text(
                                '${h}h',
                                style: GoogleFonts.dmMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? tkBackground
                                      : tkTextMid,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Visibilidad ───────────────────────
                    _SectionLabel('VISIBILIDAD'),
                    const SizedBox(height: 10),
                    Obx(
                      () => Column(
                        children: [
                          _VisibilityCard(
                            icon: Icons.people_outline_rounded,
                            label: 'Pública',
                            description:
                                'Los estudiantes ven resultados',
                            selected:
                                evalCtrl.selectedVisibility.value == 'public',
                            onTap: () =>
                                evalCtrl.setSelectedVisibility('public'),
                          ),
                          const SizedBox(height: 8),
                          _VisibilityCard(
                            icon: Icons.lock_outline_rounded,
                            label: 'Privada',
                            description:
                                'Solo el docente ve resultados',
                            selected:
                                evalCtrl.selectedVisibility.value == 'private',
                            onTap: () =>
                                evalCtrl.setSelectedVisibility('private'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Error ─────────────────────────────
                    Obx(() {
                      if (evalCtrl.evalError.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          evalCtrl.evalError.value,
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            color: tkDanger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),

                    // ── Botón ─────────────────────────────
                    Obx(
                      () => GestureDetector(
                        onTap: evalCtrl.isLoading.value
                            ? null
                            : () => evalCtrl.createEvaluation(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: evalCtrl.isLoading.value
                                ? tkGold.withValues(alpha: 0.5)
                                : tkGold,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: evalCtrl.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: tkBackground,
                                  strokeWidth: 2,
                                )
                              : Text(
                                  'Lanzar evaluación',
                                  style: GoogleFonts.sora(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: tkBackground,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Obx(() {
                      final name = evalCtrl.selectedCategoryName.value;
                      return Center(
                        child: Text(
                          name.isEmpty
                              ? 'Selecciona una categoría'
                              : 'Se notificará a $name',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: tkTextFaint,
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

  Future<void> _showCoursePicker(
    BuildContext context,
    TeacherEvaluationController evalCtrl,
    TeacherCourseImportController courseCtrl,
  ) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TNewEvalCoursePickerSheet(
        evalCtrl: evalCtrl,
        courseCtrl: courseCtrl,
      ),
    );

    if (id != null) {
      await evalCtrl.selectCourseForEvaluation(id);
    }
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    TeacherEvaluationController evalCtrl,
    TeacherCourseImportController courseCtrl,
  ) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TNewEvalCategoryPickerSheet(
        evalCtrl: evalCtrl,
        courseCtrl: courseCtrl,
      ),
    );

    if (id != null) {
      final category = courseCtrl.categoriesForCourse
          .firstWhereOrNull((c) => c.id == id);

      evalCtrl.selectCategoryForEvaluation(id, category?.name ?? '');
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: tkTextFaint,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String text;
  final bool disabled;
  final VoidCallback? onTap;

  const _SelectorCard({
    required this.text,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: tkSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: disabled ? tkBorder : tkBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: disabled ? tkTextFaint : tkText,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: tkTextFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GoldTextField({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_GoldTextField> createState() => _GoldTextFieldState();
}

class _GoldTextFieldState extends State<_GoldTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      style: GoogleFonts.sora(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: tkText,
      ),
      cursorColor: tkGold,
      decoration: InputDecoration(
        filled: true,
        fillColor: tkSurfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: tkGold.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tkGold, width: 1.5),
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? tkGoldLight : tkSurface,
          border: Border.all(color: selected ? tkGold : tkBorder),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? tkGoldBorder : tkSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected ? tkGold : tkTextMid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? tkGold : tkText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: tkTextFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}