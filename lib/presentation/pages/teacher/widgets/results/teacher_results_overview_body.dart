import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_state_cards.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

Color _scoreColor(double value) => value >= 4.0 ? tkSuccess : tkWarning;

class TeacherResultsOverviewBody extends StatelessWidget {
  final TeacherResultsOverviewVm vm;
  final ValueChanged<int> onGroupTap;

  const TeacherResultsOverviewBody({
    super.key,
    required this.vm,
    required this.onGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('results-overview-panel'),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TeacherResultsStatCard(
                  value: vm.overallAverageLabel,
                  label: 'PROMEDIO GENERAL',
                  valueColor: tkGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeacherResultsStatCard(
                  value: vm.groupCountLabel,
                  label: 'GRUPOS',
                  valueColor: tkSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'GRUPOS - toca para detalle',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tkTextFaint,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          if (!vm.hasGroups)
            const TeacherResultsEmptyStateCard()
          else
            Column(
              children: vm.groups
                  .map(
                    (groupVm) => _TeacherResultsGroupCard(
                      vm: groupVm,
                      onTap: () => onGroupTap(groupVm.index),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _TeacherResultsStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _TeacherResultsStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmMono(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: tkTextFaint,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherResultsGroupCard extends StatelessWidget {
  final TeacherResultsGroupCardVm vm;
  final VoidCallback onTap;

  const _TeacherResultsGroupCard({
    required this.vm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = _scoreColor(vm.average);

    return GestureDetector(
      key: Key('results-group-card-${vm.index}'),
      onTap: onTap,
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vm.name,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tkText,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    vm.averageLabel,
                    style: GoogleFonts.dmMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: vm.progress,
                backgroundColor: tkBorder,
                valueColor: AlwaysStoppedAnimation(scoreColor),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
