import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentResultsCriterionCard extends StatelessWidget {
  final CriterionResult result;
  final Color color;

  const StudentResultsCriterionCard({
    super.key,
    required this.result,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skSurfaceAlt,
        border: Border.all(color: skBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
              ),
              Text(
                result.value.toString(),
                style: GoogleFonts.dmMono(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: result.barFraction,
              backgroundColor: skBorder,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
