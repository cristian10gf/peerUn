import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TEvalCard extends StatelessWidget {
  final Evaluation eval;
  final TeacherResultsController resultsCtrl;

  const TEvalCard({
    super.key,
    required this.eval,
    required this.resultsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = eval.isActive;
    final closesIn = eval.closesAt.difference(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eval.name,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tkText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${eval.categoryName} · ${_fmt(closesIn)}',
            style: GoogleFonts.dmMono(
              fontSize: 10,
              color: tkTextFaint,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await resultsCtrl.loadGroupResults(eval);
              Get.toNamed('/teacher/results');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? tkGold : tkSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                'Ver resultados',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? tkBackground : tkTextMid,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.isNegative) return 'Cerrada';
    if (d.inDays > 0) return 'Cierra en ${d.inDays}d';
    if (d.inHours > 0) return 'Cierra en ${d.inHours}h';
    return 'Cierra en ${d.inMinutes}m';
  }
}