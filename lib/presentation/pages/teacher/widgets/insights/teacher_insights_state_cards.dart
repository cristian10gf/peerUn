import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherInsightsLoadingStateCard extends StatelessWidget {
  const TeacherInsightsLoadingStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: tkGold, strokeWidth: 2),
    );
  }
}

class TeacherInsightsErrorStateCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const TeacherInsightsErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = message.isEmpty ? 'Error al cargar datos' : message;

    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tkSurface,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 30, color: tkWarning),
            const SizedBox(height: 10),
            Text(
              'No se pudieron cargar los datos',
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              displayMessage,
              style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: tkBackground,
                backgroundColor: tkGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherInsightsNoEvaluationsStateCard extends StatelessWidget {
  final VoidCallback onCreateEvaluation;

  const TeacherInsightsNoEvaluationsStateCard({
    super.key,
    required this.onCreateEvaluation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tkSurface,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.query_stats_rounded, size: 32, color: tkTextFaint),
            const SizedBox(height: 10),
            Text(
              'Aun no tienes evaluaciones',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Crea tu primera evaluacion para ver metricas globales.',
              style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onCreateEvaluation,
              style: TextButton.styleFrom(
                foregroundColor: tkBackground,
                backgroundColor: tkGold,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Crear evaluacion',
                style: GoogleFonts.sora(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherInsightsNoResponsesStateCard extends StatelessWidget {
  const TeacherInsightsNoResponsesStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(22),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tkSurface,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 32, color: tkTextFaint),
            const SizedBox(height: 10),
            Text(
              'Aun no hay respuestas registradas',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Los indicadores apareceran cuando haya evaluaciones enviadas.',
              style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
