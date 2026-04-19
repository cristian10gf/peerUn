import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherResultsLoadingStateCard extends StatelessWidget {
  const TeacherResultsLoadingStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: tkGold,
        strokeWidth: 2,
      ),
    );
  }
}

class TeacherResultsEmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const TeacherResultsEmptyStateCard({
    super.key,
    this.title = 'Sin respuestas a\u00fan',
    this.subtitle =
        'Los resultados aparecer\u00e1n cuando los\nestudiantes env\u00eden sus evaluaciones',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 32,
            color: tkTextFaint,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tkTextMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.sora(fontSize: 11, color: tkTextFaint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TeacherResultsErrorStateCard extends StatelessWidget {
  final String message;

  const TeacherResultsErrorStateCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message.isEmpty ? 'Error al cargar resultados' : message;

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
            const Icon(
              Icons.error_outline,
              size: 30,
              color: tkWarning,
            ),
            const SizedBox(height: 10),
            Text(
              'No se pudieron cargar los resultados',
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
              style: GoogleFonts.sora(
                fontSize: 11,
                color: tkTextFaint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}