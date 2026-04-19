import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherCourseAverageSection extends StatelessWidget {
  final List<TeacherInsightsCourseAverageVm> items;

  const TeacherCourseAverageSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CURSOS',
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tkTextFaint,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const _SectionEmptyCard(message: 'Sin datos suficientes por curso')
        else
          ...items.map((item) => _CourseAverageCard(item: item)),
      ],
    );
  }
}

class _CourseAverageCard extends StatelessWidget {
  final TeacherInsightsCourseAverageVm item;

  const _CourseAverageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.courseName,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.averageLabel,
            style: GoogleFonts.dmMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: item.average >= 4.0 ? tkSuccess : tkWarning,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'n=${item.sampleCountLabel}',
            style: GoogleFonts.dmMono(fontSize: 10, color: tkTextFaint),
          ),
        ],
      ),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  final String message;

  const _SectionEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
      ),
    );
  }
}
