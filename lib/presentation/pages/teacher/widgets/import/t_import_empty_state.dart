import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TImportEmptyState extends StatelessWidget {
  const TImportEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.folder_open_rounded, size: 32, color: tkTextFaint),
          const SizedBox(height: 10),
          Text(
            'Sin categorías importadas',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: tkTextFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Usa el botón de arriba para cargar un CSV',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: tkTextFaint,
            ),
          ),
        ],
      ),
    );
  }
}
