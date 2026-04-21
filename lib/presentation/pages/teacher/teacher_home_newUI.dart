import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';

class TeacherHomeNewUI extends StatelessWidget {
  const TeacherHomeNewUI({super.key});

  @override
  Widget build(BuildContext context) {
    final courseCtrl = Get.find<TeacherCourseImportController>();
    final sessionCtrl = Get.find<TeacherSessionController>();
    final evalCtrl = Get.find<TeacherEvaluationController>();
    final resultsCtrl = Get.find<TeacherResultsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── Header ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text("UniMejores", style: TextStyle(letterSpacing: 2)),

                  const Spacer(),

                  // 🆕 Botón criterios
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/teacher/criteria');
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.checklist_rounded,
                        size: 22,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Body ───────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📝 Texto principal
                    Text(
                      "Con que materia quieres\nempezar a calificar?",
                      style: GoogleFonts.sora(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Elije la que te guste mas.",
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🎯 Cursos
                    Obx(() {
                      if (courseCtrl.courses.isEmpty) {
                        return const Text("No hay cursos aún");
                      }

                      return SizedBox(
                        height: 170,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: courseCtrl.courses.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final course = courseCtrl.courses[i];

                            return _courseCard(
                              title: course.name,
                              subtitle: "${courseCtrl.totalGroupsForCourse(course.id)} grupos",
                              color: i.isEven
                                  ? const Color(0xFF7B83EB)
                                  : const Color(0xFFF4B860),
                              onTap: () {
                                courseCtrl.loadCategoriesForCourse(course.id);

                                Get.toNamed(
                                  '/teacher/course',
                                  arguments: course.id,
                                );
                              },
                            );
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // ➕ Crear curso
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.toNamed('/teacher/new-course');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B83EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text("CREAR UN NUEVO CURSO"),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 📊 Evaluaciones
                    Text(
                      "Analiza el estado de tus evaluaciones",
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Obx(() {
                      if (evalCtrl.evaluations.isEmpty) {
                        return const Text("Sin evaluaciones");
                      }

                      return Column(
                        children: evalCtrl.evaluations.map((e) {
                          final isActive = e.isActive;

                          return GestureDetector(
                            onTap: () async {
                              await resultsCtrl.loadGroupResults(e);
                              Get.toNamed('/teacher/eval-results');
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // 🔵 Indicador visual mejorado
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(
                                              0xFF7B83EB,
                                            ).withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      isActive ? Icons.play_arrow : Icons.check,
                                      size: 18,
                                      color: isActive
                                          ? const Color(0xFF7B83EB)
                                          : Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 📝 Texto
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.name,
                                          style: GoogleFonts.sora(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Cierra: ${e.closesAt.day}/${e.closesAt.month}/${e.closesAt.year}",
                                          style: GoogleFonts.sora(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Bottom Nav ─────────────────────────
            const TeacherBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _courseCard({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        // 👇 Stack para meter decoraciones
        child: Stack(
          children: [
            // 🌊 Forma decorativa (tipo Figma)
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // 🧱 Contenido
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),

                const SizedBox(height: 12),

                // 🔘 Botón moderno
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "COMIENZA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 👤 Profile modal
  void _showProfile(
    BuildContext context,
    TeacherSessionController sessionCtrl,
  ) {
    final teacher = sessionCtrl.teacher.value;
    if (teacher == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(teacher.name),
            Text(teacher.email),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => sessionCtrl.logout(),
              child: const Text("Cerrar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}
