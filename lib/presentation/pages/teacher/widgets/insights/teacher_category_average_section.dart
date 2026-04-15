import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherCategoryAverageSection extends StatelessWidget {
  final List<TeacherInsightsCategoryAverageVm> items;

  const TeacherCategoryAverageSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORIAS',
          style: GoogleFonts.sora(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: tkTextFaint,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const _SectionEmptyCard(
            message: 'Sin datos suficientes por categoria',
          )
        else
          ...items.map((item) => _CategoryAverageCard(item: item)),
      ],
    );
  }
}

class _CategoryAverageCard extends StatelessWidget {
  final TeacherInsightsCategoryAverageVm item;

  const _CategoryAverageCard({required this.item});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.categoryName,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.courseName,
            style: GoogleFonts.dmMono(fontSize: 10, color: tkTextFaint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
