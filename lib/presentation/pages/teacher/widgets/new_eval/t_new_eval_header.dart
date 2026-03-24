import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';

class TNewEvalHeader extends StatelessWidget {
  const TNewEvalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TeacherBackButton(label: 'Volver', route: '/teacher/dash'),
          const SizedBox(height: 16),
          Text(
            'Nueva evaluación',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tkText,
            ),
          ),
        ],
      ),
    );
  }
}
