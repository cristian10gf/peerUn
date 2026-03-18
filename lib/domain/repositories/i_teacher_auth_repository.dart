import 'package:example/domain/models/teacher.dart';

abstract interface class ITeacherAuthRepository {
  Future<Teacher?> login(String email, String password);
  Future<Teacher>  register(String name, String email, String password);
  Future<void>     logout();
  Future<Teacher?> getCurrentSession();
}
