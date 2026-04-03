import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentCourseHeader extends StatelessWidget {
  final String name;

  const StudentCourseHeader({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, size: 13, color: skPrimary),
          const SizedBox(width: 6),
          Text(
            name.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: skPrimary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
