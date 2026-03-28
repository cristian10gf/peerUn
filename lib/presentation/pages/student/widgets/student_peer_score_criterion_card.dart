import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/domain/models/peer_evaluation.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentPeerScoreCriterionCard extends StatelessWidget {
  final EvalCriterion criterion;
  final StudentController ctrl;
  final Color color;

  const StudentPeerScoreCriterionCard({
    super.key,
    required this.criterion,
    required this.ctrl,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            final score = ctrl.scores[criterion.id];
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  criterion.label,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: skText,
                  ),
                ),
                if (score != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score.0',
                      style: GoogleFonts.dmMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [2, 3, 4, 5].map((value) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: value < 5 ? 5 : 0),
                  child: Obx(() {
                    final selected = ctrl.scores[criterion.id] == value;
                    return GestureDetector(
                      onTap: () => ctrl.setScore(criterion.id, value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? color : skSurface,
                          border: Border.all(
                            color: selected ? color : skBorder,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$value',
                          style: GoogleFonts.dmMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : skTextFaint,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final score = ctrl.scores[criterion.id];
            return Center(
              child: Text(
                score != null
                    ? EvalCriterion.levelFor(score).toUpperCase()
                    : '- SELECCIONA UN NIVEL -',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: skTextFaint,
                  letterSpacing: 0.3,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
