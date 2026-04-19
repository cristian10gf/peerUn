import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_back_button.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherInsightsHeader extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onRefreshTap;
  final DateTime? lastUpdatedAt;

  const TeacherInsightsHeader({
    super.key,
    required this.onBackTap,
    required this.onRefreshTap,
    required this.lastUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TeacherBackButton(
                key: const Key('insights-back-button'),
                backgroundColor: tkPurple,
                iconColor: tkText,
                onTap: onBackTap,
              ),
              IconButton(
                key: const Key('insights-refresh-button'),
                onPressed: onRefreshTap,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: tkTextMid,
                  size: 18,
                ),
                tooltip: 'Recargar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Datos globales',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tkText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _lastUpdatedLabel(lastUpdatedAt),
            style: GoogleFonts.dmMono(fontSize: 11, color: tkTextFaint),
          ),
        ],
      ),
    );
  }

  String _lastUpdatedLabel(DateTime? value) {
    if (value == null) {
      return 'Actualizacion pendiente';
    }

    final date =
        '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return 'Actualizado: $date $time';
  }
}
