import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/new_eval/t_new_eval_picker_sheets.dart';

class TeacherCreateEvalNewUI extends StatelessWidget {
  const TeacherCreateEvalNewUI({super.key});

  @override
  Widget build(BuildContext context) {
    final evalCtrl = Get.find<TeacherEvaluationController>();
    final courseCtrl = Get.find<TeacherCourseImportController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "CREAR EVALUACIÓN",
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🎓 CONTEXTO DEL CURSO (NUEVO)
            Obx(() {
              final courseName = courseCtrl.selectedCourseName.value;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B83EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book, color: Color(0xFF7B83EB)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        courseName.isEmpty
                            ? "Curso no seleccionado"
                            : courseName,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7B83EB),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 📝 Nombre
                    Obx(
                      () => _InputCard(
                        hint: "Nombre",
                        value: evalCtrl.evalName.value,
                        onChanged: evalCtrl.setEvalName,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 📁 Categoría (YA filtrada por curso)
                    Obx(() {
                      final name = evalCtrl.selectedCategoryName.value;

                      return _SelectorInput(
                        text: name.isEmpty ? "Seleccionar categoría" : name,
                        onTap: () =>
                            _showCategoryPicker(context, evalCtrl, courseCtrl),
                      );
                    }),

                    const SizedBox(height: 12),

                    // 📝 Descripción (UI)
                    const _InputCard(hint: "Descripción", enabled: false),

                    const SizedBox(height: 12),

                    // 📅 Fecha (placeholder)
                    const _SelectorInput(text: "Fecha de finalización"),

                    const SizedBox(height: 16),

                    // ⏱ Duración
                    Obx(
                      () => Wrap(
                        spacing: 10,
                        children: [24, 48, 72].map((h) {
                          final selected = evalCtrl.selectedHours.value == h;

                          return GestureDetector(
                            onTap: () => evalCtrl.setSelectedHours(h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF7B83EB)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${h}h",
                                style: GoogleFonts.sora(
                                  color: selected
                                      ? Colors.white
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 👁️ VISIBILIDAD (RESTAURADA)
                    Obx(
                      () => Column(
                        children: [
                          _VisibilityCard(
                            label: "Pública",
                            description: "Los estudiantes ven resultados",
                            selected:
                                evalCtrl.selectedVisibility.value == 'public',
                            onTap: () =>
                                evalCtrl.setSelectedVisibility('public'),
                          ),
                          const SizedBox(height: 8),
                          _VisibilityCard(
                            label: "Privada",
                            description: "Solo el docente ve resultados",
                            selected:
                                evalCtrl.selectedVisibility.value == 'private',
                            onTap: () =>
                                evalCtrl.setSelectedVisibility('private'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔴 Error
                    Obx(() {
                      if (evalCtrl.evalError.value.isEmpty) {
                        return const SizedBox();
                      }

                      return Text(
                        evalCtrl.evalError.value,
                        style: const TextStyle(color: Colors.red),
                      );
                    }),

                    const SizedBox(height: 20),

                    // 💾 BOTÓN
                    Obx(
                      () => GestureDetector(
                        onTap: evalCtrl.isLoading.value
                            ? null
                            : () {
                                // 🔥 CLAVE: usar el curso actual
                                evalCtrl.createEvaluation();

                                evalCtrl.createEvaluation();
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B83EB),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: evalCtrl.isLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "GUARDAR",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    TeacherEvaluationController evalCtrl,
    TeacherCourseImportController courseCtrl,
  ) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => TNewEvalCategoryPickerSheet(
        evalCtrl: evalCtrl,
        courseCtrl: courseCtrl,
      ),
    );

    if (id != null) {
      final category = courseCtrl.categoriesForCourse.firstWhereOrNull(
        (c) => c.id == id,
      );

      evalCtrl.selectCategoryForEvaluation(id, category?.name ?? '');
    }
  }
}

// ── COMPONENTES ─────────────────────────────

class _InputCard extends StatelessWidget {
  final String hint;
  final String? value;
  final bool enabled;
  final Function(String)? onChanged;

  const _InputCard({
    required this.hint,
    this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value ?? '');

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SelectorInput extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _SelectorInput({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: const TextStyle(color: Colors.black54)),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityCard({
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
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF7B83EB).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.sora(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
