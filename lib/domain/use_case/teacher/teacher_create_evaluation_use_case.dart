import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';

class TeacherCreateEvaluationInput {
  final String name;
  final int? categoryId;
  final int hours;
  final String visibility;
  final int teacherId;

  const TeacherCreateEvaluationInput({
    required this.name,
    required this.categoryId,
    required this.hours,
    required this.visibility,
    required this.teacherId,
  });
}

class TeacherCreateEvaluationUseCase {
  final IEvaluationRepository _evaluationRepository;

  const TeacherCreateEvaluationUseCase(this._evaluationRepository);

  Future<Evaluation> execute(TeacherCreateEvaluationInput input) async {
    final trimmedName = input.name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('El nombre de la evaluación es obligatorio');
    }

    final categoryId = input.categoryId;
    if (categoryId == null) {
      throw Exception('Selecciona una categoría de grupos');
    }

    if (input.hours <= 0) {
      throw Exception('La duración debe ser mayor a 0 horas');
    }

    if (input.visibility != 'public' && input.visibility != 'private') {
      throw Exception('La visibilidad seleccionada no es válida');
    }

    return _evaluationRepository.create(
      name: trimmedName,
      categoryId: categoryId,
      hours: input.hours,
      visibility: input.visibility,
      teacherId: input.teacherId,
    );
  }
}
