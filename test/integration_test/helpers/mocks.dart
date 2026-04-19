import 'package:example/domain/repositories/i_auth_repository.dart';
import 'package:example/domain/repositories/i_course_repository.dart';
import 'package:example/domain/repositories/i_evaluation_repository.dart';
import 'package:example/domain/repositories/i_group_repository.dart';
import 'package:example/domain/repositories/i_teacher_auth_repository.dart';
import 'package:example/domain/repositories/i_unified_auth_repository.dart';
import 'package:mockito/annotations.dart';

export 'mocks.mocks.dart';

@GenerateMocks([
  IEvaluationRepository,
  IAuthRepository,
  ICourseRepository,
  IGroupRepository,
  ITeacherAuthRepository,
  IUnifiedAuthRepository,
])
void main() {}
