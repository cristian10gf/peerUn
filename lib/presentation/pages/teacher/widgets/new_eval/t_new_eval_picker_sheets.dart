import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/course_model.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

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
    return Column(
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
            title,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tkText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map((item) {
          final id = itemId(item);
          final selected = selectedId == id;
          final detail = (secondaryText?.call(item) ?? '').trim();
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pop<int>(id);
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
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: tkTextFaint,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: tkGold,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
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
        title: 'Curso',
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
        title: 'Categoría de grupos',
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
