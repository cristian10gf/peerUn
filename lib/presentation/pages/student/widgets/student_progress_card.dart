import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/theme/app_colors.dart';

class StudentProgressCard extends StatelessWidget {
  final double progress;
  final int percentage;

  const StudentProgressCard({
    super.key,
    required this.progress,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: skTextMid),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Evaluacion en curso',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.dmMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: skPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: skBorder,
              valueColor: const AlwaysStoppedAnimation(skPrimary),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}
