import 'package:example/domain/models/student.dart';

abstract class IAuthRepository {
  Future<Student?> login(String email, String password);
  Future<Student>  register(String name, String email, String password);
  Future<void>     logout();
  Future<Student?> getCurrentSession();
}
