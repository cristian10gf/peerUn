import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherImportError extends StatelessWidget {
  final String message;

  const TeacherImportError({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        message,
        style: GoogleFonts.sora(
          fontSize: 12,
          color: tkDanger,
        ),
      ),
    );
  }
}