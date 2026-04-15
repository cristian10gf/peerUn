import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks([IEvaluationRepository, IAuthRepository])
void main() {}
