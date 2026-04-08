import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TDashStatsRow extends StatelessWidget {
  final String categories;
  final String active;
  final String groups;

  const TDashStatsRow({
    super.key,
    required this.categories,
    required this.active,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(value: categories, label: 'CATEGORÍAS'),
        const SizedBox(width: 8),
        _StatCard(value: active, label: 'ACTIVAS'),
        const SizedBox(width: 8),
        _StatCard(value: groups, label: 'GRUPOS'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: tkSurfaceAlt,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.dmMono(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: tkText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tkTextFaint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}