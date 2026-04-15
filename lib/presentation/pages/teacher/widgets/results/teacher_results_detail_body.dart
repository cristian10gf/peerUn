import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/constants/evaluation_ui_constants.dart';
import 'package:example/presentation/models/teacher_results_view_model.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

const _kAvatarColors = [tkBlue, tkPurple, tkSuccess, tkPink];

Color _scoreColor(double value) => value >= 4.0 ? tkSuccess : tkWarning;

class TeacherResultsDetailBody extends StatelessWidget {
  final TeacherResultsDetailVm vm;

  const TeacherResultsDetailBody({
    super.key,
    required this.vm,
  });

  static final _ringColors = EvaluationUiConstants.criteriaColors
      .map((value) => Color(value.toInt()))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('results-detail-panel'),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: tkSurface,
              border: Border.all(color: tkBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: vm.criteria
                  .asMap()
                  .entries
                  .map(
                    (entry) => _CriterionRing(
                      value: entry.value.scoreLabel,
                      label: entry.value.label,
                      progress: entry.value.progress,
                      color: _ringColors[entry.key % _ringColors.length],
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'ESTUDIANTES',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tkTextFaint,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...vm.students.asMap().entries.map(
            (entry) => _StudentCard(
              vm: entry.value,
              avatarColor: _kAvatarColors[entry.key % _kAvatarColors.length],
            ),
          ),
        ],
      ),
    );
  }
}

class _CriterionRing extends StatelessWidget {
  final String value;
  final String label;
  final double progress;
  final Color color;

  const _CriterionRing({
    required this.value,
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: tkSurfaceAlt,
                valueColor: AlwaysStoppedAnimation(color),
                strokeWidth: 4,
              ),
              Text(
                value,
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: tkText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            color: tkTextFaint,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  final TeacherResultsStudentVm vm;
  final Color avatarColor;

  const _StudentCard({
    required this.vm,
    required this.avatarColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              vm.initial,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: avatarColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              vm.name,
              style: GoogleFonts.sora(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tkText,
              ),
            ),
          ),
          Text(
            vm.scoreLabel,
            style: GoogleFonts.dmMono(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _scoreColor(vm.score),
            ),
          ),
        ],
      ),
    );
  }
}
