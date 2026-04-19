import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';

class TeacherCreateCategoryPage extends StatelessWidget {
  const TeacherCreateCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                    "IMPORTAR CATEGORÍA",
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── BODY ───────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Obx(() {
                  final isLoading = courseCtrl.importLoading.value;

                  return Column(
                    children: [
                      // 📂 IMPORT BOX
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () async {
                                final courseId =
                                    courseCtrl.selectedCourseId.value;

                                if (courseId == null) return;

                                final result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['csv'],
                                );

                                if (result == null) return;

                                final file =
                                    File(result.files.single.path!);

                                final csvContent =
                                    await file.readAsString();

                                final fileName =
                                    result.files.single.name;

                                await courseCtrl.importCsvFromFilename(
                                  csvContent,
                                  fileName,
                                  courseId,
                                );

                                Get.back(); // vuelve al curso
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B83EB)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF7B83EB),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isLoading
                                    ? Icons.hourglass_empty
                                    : Icons.upload_file,
                                size: 42,
                                color: const Color(0xFF7B83EB),
                              ),
                              const SizedBox(height: 12),

                              Text(
                                isLoading
                                    ? "Importando..."
                                    : "Importar desde Brightspace",
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7B83EB),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                isLoading
                                    ? courseCtrl.importProgress.value
                                    : "CSV con categorías y grupos",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isLoading
                                      ? Colors.grey
                                      : const Color(0xFF7B83EB),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isLoading
                                      ? "Procesando..."
                                      : "Seleccionar archivo",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ⚠️ ERROR
                      Obx(() {
                        if (courseCtrl.importError.value.isEmpty) {
                          return const SizedBox();
                        }

                        return Text(
                          courseCtrl.importError.value,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        );
                      }),

                      const SizedBox(height: 10),

                      // 🧠 INFO UX
                      Text(
                        "El nombre de la categoría se generará automáticamente a partir del archivo",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}