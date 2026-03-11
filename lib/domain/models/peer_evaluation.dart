import 'package:flutter/material.dart';
import 'package:example/presentation/theme/app_colors.dart';

class Peer {
  final String id;
  final String name;
  final String initials;
  bool evaluated;
  Map<String, int> scores; // criterionId → score (2..5)

  Peer({
    required this.id,
    required this.name,
    required this.initials,
    this.evaluated = false,
    Map<String, int>? scores,
  }) : scores = scores ?? {};
}

class EvalCriterion {
  final String id;
  final String label;
  final Color color;

  const EvalCriterion({
    required this.id,
    required this.label,
    required this.color,
  });

  static const List<EvalCriterion> defaults = [
    EvalCriterion(id: 'punct',    label: 'Puntualidad',    color: critBlue),
    EvalCriterion(id: 'contrib',  label: 'Contribuciones', color: critPurple),
    EvalCriterion(id: 'commit',   label: 'Compromiso',     color: critGreen),
    EvalCriterion(id: 'attitude', label: 'Actitud',        color: critAmber),
  ];

  static const List<String> levelLabels = [
    'Necesita Mejorar',
    'Adecuado',
    'Bueno',
    'Excelente',
  ];

  static String levelFor(int score) => levelLabels[score - 2];
}

class CriterionResult {
  final String label;
  final double value;
  final Color color;

  const CriterionResult({
    required this.label,
    required this.value,
    required this.color,
  });

  double get barFraction => ((value - 2) / 3).clamp(0.0, 1.0);
}
