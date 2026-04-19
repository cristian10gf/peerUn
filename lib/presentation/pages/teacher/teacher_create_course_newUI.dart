import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';

class TeacherCreateCourseNewUI extends StatelessWidget {
  const TeacherCreateCourseNewUI({super.key});

  @override
  Widget build(BuildContext context) {
    final courseCtrl = Get.find<TeacherCourseImportController>();

    // 🔥 Controllers locales (IMPORTANTE)
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

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
                    "CREAR CURSO",
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── BODY ───────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 📝 Nombre
                    _InputCard(
                      hint: "Nombre",
                      controller: nameCtrl,
                    ),

                    const SizedBox(height: 12),

                    // 🔢 NRC
                    _InputCard(
                      hint: "NRC",
                      controller: codeCtrl,
                    ),

                    const SizedBox(height: 20),

                    // 🔴 ERROR (usa tu controller)
                    Obx(() {
                      if (courseCtrl.courseCreateError.value.isEmpty) {
                        return const SizedBox();
                      }

                      return Text(
                        courseCtrl.courseCreateError.value,
                        style: const TextStyle(color: Colors.red),
                      );
                    }),

                    const SizedBox(height: 30),

                    // 💾 BOTÓN
                    Obx(
                      () => GestureDetector(
                        onTap: courseCtrl.courseCreateLoading.value
                            ? null
                            : () async {
                                final success =
                                    await courseCtrl.createCourse(
                                  nameCtrl.text,
                                  codeCtrl.text,
                                );

                                if (success) {
                                  Get.back(); // vuelve al home
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B83EB),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          alignment: Alignment.center,
                          child: courseCtrl.courseCreateLoading.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "GUARDAR",
                                  style: GoogleFonts.sora(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
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
}

// ── INPUT ─────────────────────────────
class _InputCard extends StatelessWidget {
  final String hint;
  final TextEditingController controller;

  const _InputCard({
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFEDEDED),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}