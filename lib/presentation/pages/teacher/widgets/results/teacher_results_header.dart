import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherResultsHeader extends StatelessWidget {
  final String backLabel;
  final String title;
  final String subtitle;
  final VoidCallback onBackTap;

  const TeacherResultsHeader({
    super.key,
    required this.backLabel,
    required this.title,
    required this.subtitle,
    required this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeacherBackButton(
            key: const Key('results-back-button'),
            label: backLabel,
            onTap: onBackTap,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tkText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: tkTextFaint,
            ),
          ),
        ],
      ),
    );
  }
}
