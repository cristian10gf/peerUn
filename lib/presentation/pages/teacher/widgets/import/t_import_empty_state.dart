import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TImportEmptyState extends StatelessWidget {
  const TImportEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: tkSurfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tkTextFaint.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_open_rounded,
              size: 28,
              color: tkTextFaint,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Sin categorías',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tkText,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Importa un archivo CSV para comenzar',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: tkTextFaint,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}