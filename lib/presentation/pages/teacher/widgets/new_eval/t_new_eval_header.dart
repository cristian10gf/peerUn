import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';

class TNewEvalHeader extends StatelessWidget {
  const TNewEvalHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TeacherBackButton(
            backgroundColor: tkSurfaceAlt,
            iconColor: tkText,
            onTap: () => Get.back(),
          ),

          const SizedBox(height: 16),

          Text(
            'Nueva evaluación',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tkText,
            ),
          ),
        ],
      ),
    );
  }
}