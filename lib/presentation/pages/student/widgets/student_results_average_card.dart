import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/theme/app_colors.dart';

class StudentResultsAverageCard extends StatelessWidget {
  final double average;
  final String badge;

  const StudentResultsAverageCard({
    super.key,
    required this.average,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            average.toStringAsFixed(2),
            style: GoogleFonts.dmMono(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: skPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Promedio general recibido',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: skTextFaint,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: skSuccess.withValues(alpha: 0.09),
              border: Border.all(color: skSuccess.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: skSuccess,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
