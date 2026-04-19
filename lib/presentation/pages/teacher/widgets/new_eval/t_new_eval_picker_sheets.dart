import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';

class _TNewEvalSelectionPickerSheet<T> extends StatelessWidget {
  final String title;
  final List<T> items;
  final int? selectedId;
  final int Function(T item) itemId;
  final String Function(T item) primaryText;
  final String Function(T item)? secondaryText;

  const _TNewEvalSelectionPickerSheet({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.itemId,
    required this.primaryText,
    this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔘 drag indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: tkBorder,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 16),

            /// 🧠 title
            Text(
              title,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),

            const SizedBox(height: 16),

            /// 📋 items
            ...items.map((item) {
              final id = itemId(item);
              final selected = selectedId == id;
              final detail = (secondaryText?.call(item) ?? '').trim();

              return GestureDetector(
                onTap: () => Get.back(result: id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? tkGold.withOpacity(0.12) : tkSurfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      /// text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primaryText(item),
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: selected ? tkGold : tkText,
                              ),
                            ),
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: GoogleFonts.sora(
                                  fontSize: 11,
                                  color: tkTextFaint,
                                ),
                              ),
                          ],
                        ),
                      ),

                      /// check
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: tkGold,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

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
      () => _TNewEvalSelectionPickerSheet<CourseModel>(
        title: 'Selecciona un curso',
        items: courseCtrl.courses,
        selectedId: courseCtrl.selectedCourseId.value,
        itemId: (course) => course.id,
        primaryText: (course) => course.name,
        secondaryText: (course) => course.code,
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
      () => _TNewEvalSelectionPickerSheet<GroupCategory>(
        title: 'Selecciona una categoría',
        items: courseCtrl.categoriesForCourse,
        selectedId: evalCtrl.selectedCategoryId.value,
        itemId: (category) => category.id,
        primaryText: (category) => category.name,
        secondaryText: (category) =>
            '${category.groupCount} grupos · ${category.studentCount} estudiantes',
      ),
    );
  }
}