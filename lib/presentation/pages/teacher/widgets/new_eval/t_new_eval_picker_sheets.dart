import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TNewEvalCoursePickerSheet extends StatelessWidget {
  final TeacherEvaluationController evalCtrl;
  final TeacherCourseImportController courseCtrl;

  const TNewEvalCoursePickerSheet({
    super.key,
    required this.evalCtrl,
    required this.courseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tkBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'Curso',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...courseCtrl.courses.map((course) {
            final selected = courseCtrl.selectedCourseId.value == course.id;
            return GestureDetector(
              onTap: () async {
                await evalCtrl.selectCourseForEvaluation(course.id);
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? tkGoldLight : tkSurface,
                  border: Border(bottom: BorderSide(color: tkBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? tkGold : tkText,
                            ),
                          ),
                          if (course.code.isNotEmpty)
                            Text(
                              course.code,
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: tkTextFaint,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded, size: 18, color: tkGold),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TNewEvalCategoryPickerSheet extends StatelessWidget {
  final TeacherEvaluationController evalCtrl;
  final TeacherCourseImportController courseCtrl;

  const TNewEvalCategoryPickerSheet({
    super.key,
    required this.evalCtrl,
    required this.courseCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tkBorder,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'Categoría de grupos',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...courseCtrl.categoriesForCourse.map((cat) {
            final selected = evalCtrl.selectedCategoryId.value == cat.id;
            return GestureDetector(
              onTap: () {
                evalCtrl.selectCategoryForEvaluation(cat.id, cat.name);
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? tkGoldLight : tkSurface,
                  border: Border(bottom: BorderSide(color: tkBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected ? tkGold : tkText,
                            ),
                          ),
                          Text(
                            '${cat.groupCount} grupos · ${cat.studentCount} estudiantes',
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: tkTextFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle_rounded, size: 18, color: tkGold),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
