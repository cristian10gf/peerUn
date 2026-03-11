import 'package:example/domain/models/auth_login_result.dart';

abstract class IUnifiedAuthRepository {
  Future<AuthLoginResult?> loginAndResolve(String email, String password);
}
