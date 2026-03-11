enum AppUserRole { student, teacher }

class AuthLoginResult {
  final AppUserRole role;

  const AuthLoginResult({required this.role});

  String get homeRoute {
    switch (role) {
      case AppUserRole.teacher:
        return '/teacher/dash';
      case AppUserRole.student:
        return '/student/courses';
    }
  }
}
