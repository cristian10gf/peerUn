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

  const EvalCriterion({required this.id, required this.label});

  static const List<EvalCriterion> defaults = [
    EvalCriterion(id: 'punct',    label: 'Puntualidad'),
    EvalCriterion(id: 'contrib',  label: 'Contribuciones'),
    EvalCriterion(id: 'commit',   label: 'Compromiso'),
    EvalCriterion(id: 'attitude', label: 'Actitud'),
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

  const CriterionResult({required this.label, required this.value});

  double get barFraction => ((value - 2) / 3).clamp(0.0, 1.0);
}
