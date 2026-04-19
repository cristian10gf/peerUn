import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/evaluation.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TActiveEvalCard extends StatelessWidget {
  final Evaluation eval;
  final TeacherResultsController resultsCtrl;

  const TActiveEvalCard({
    super.key,
    required this.eval,
    required this.resultsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final closesIn = eval.closesAt.difference(DateTime.now());

    return GestureDetector(
      onTap: () async {
        await resultsCtrl.loadGroupResults(eval);
        Get.toNamed('/teacher/results');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tkGoldLight,
          border: Border.all(color: tkGoldBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EN CURSO',
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tkGold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              eval.name,
              style: GoogleFonts.sora(
                fontSize: 14,
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
          ],
        ),
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