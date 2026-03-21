import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher_controller.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/auth/widgets/auth_field.dart';
//import 'package:example/presentation/theme/teacher_colors.dart';

class RegisterPage extends StatefulWidget {
  final AppUserRole initialRole;

  const RegisterPage({super.key, this.initialRole = AppUserRole.student});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _localError;
  late AppUserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    final routeRole = Get.arguments;
    if (routeRole is AppUserRole) {
      _selectedRole = routeRole;
    } else {
      _selectedRole = widget.initialRole;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(
    StudentController studentCtrl,
    TeacherController teacherCtrl,
  ) async {
    setState(() => _localError = null);
    studentCtrl.authError.value = '';
    teacherCtrl.authError.value = '';

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _localError = 'Completa todos los campos');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _localError = 'Correo electrónico inválido');
      return;
    }
    if (password.length < 6) {
      setState(
        () => _localError = 'La contraseña debe tener al menos 6 caracteres',
      );
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Las contraseñas no coinciden');
      return;
    }

    if (_selectedRole == AppUserRole.student) {
      await studentCtrl.register(name, email, password);
      return;
    }

    await teacherCtrl.register(name, email, password);
  }

  @override
  Widget build(BuildContext context) {
    final studentCtrl = Get.find<StudentController>();
    final teacherCtrl = Get.find<TeacherController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? tkBackground : skBackground;
    final cardColor = isDark ? tkSurface : skSurface;
    final fieldColor = isDark ? tkSurfaceAlt : skSurfaceAlt;
    final borderColor = isDark ? tkBorder : skBorder;
    final textColor = isDark ? tkText : skText;
    final mutedTextColor = isDark ? tkTextFaint : skTextFaint;
    final accentColor = isDark ? tkGold : skPrimary;
    final buttonTextColor = isDark ? const Color(0xFF0E1117) : Colors.white;
    final errorColor = isDark ? tkDanger : Colors.red.shade400;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? tkGoldLight : skPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: isDark
                              ? Border.all(color: tkGoldBorder)
                              : null,
                        ),
                        child: Icon(
                          Icons.person_add_alt_1_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: isDark
                            ? 'Cambiar a modo claro'
                            : 'Cambiar a modo oscuro',
                        onPressed: () {
                          Get.changeThemeMode(
                            isDark ? ThemeMode.light : ThemeMode.dark,
                          );
                        },
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Crear cuenta',
                    style: GoogleFonts.sora(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Desliza para cambiar el tipo de cuenta.',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: CupertinoSlidingSegmentedControl<AppUserRole>(
                      groupValue: _selectedRole,
                      thumbColor: isDark ? tkGold : skPrimary,
                      backgroundColor: fieldColor,
                      children: {
                        AppUserRole.student: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            'Estudiante',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedRole == AppUserRole.student
                                  ? buttonTextColor
                                  : textColor,
                            ),
                          ),
                        ),
                        AppUserRole.teacher: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            'Profesor',
                            style: GoogleFonts.sora(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _selectedRole == AppUserRole.teacher
                                  ? buttonTextColor
                                  : textColor,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedRole = value;
                          _localError = null;
                        });
                        studentCtrl.authError.value = '';
                        teacherCtrl.authError.value = '';
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthField(
                    controller: _nameCtrl,
                    hint: 'Nombre completo',
                    icon: Icons.person_outline_rounded,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    borderColor: borderColor,
                    fieldColor: fieldColor,
                    accentColor: accentColor,
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _emailCtrl,
                    hint: _selectedRole == AppUserRole.teacher
                        ? 'Correo institucional'
                        : 'Correo electrónico',
                    icon: Icons.mail_outline_rounded,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    borderColor: borderColor,
                    fieldColor: fieldColor,
                    accentColor: accentColor,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _passwordCtrl,
                    hint: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    borderColor: borderColor,
                    fieldColor: fieldColor,
                    accentColor: accentColor,
                    obscure: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: mutedTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscurePass = !_obscurePass);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _confirmCtrl,
                    hint: 'Confirmar contraseña',
                    icon: Icons.lock_outline_rounded,
                    textColor: textColor,
                    mutedTextColor: mutedTextColor,
                    borderColor: borderColor,
                    fieldColor: fieldColor,
                    accentColor: accentColor,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: mutedTextColor,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_localError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _localError!,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: errorColor,
                        ),
                      ),
                    ),
                  Obx(() {
                    final err = _selectedRole == AppUserRole.student
                        ? studentCtrl.authError.value
                        : teacherCtrl.authError.value;
                    if (err.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        err,
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: errorColor,
                        ),
                      ),
                    );
                  }),
                  Obx(() {
                    final loading = _selectedRole == AppUserRole.student
                        ? studentCtrl.isLoading.value
                        : teacherCtrl.isLoading.value;

                    return GestureDetector(
                      onTap: loading
                          ? null
                          : () => _submit(studentCtrl, teacherCtrl),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: loading
                              ? accentColor.withValues(alpha: 0.7)
                              : accentColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: buttonTextColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _selectedRole == AppUserRole.student
                                      ? 'Crear cuenta de estudiante'
                                      : 'Crear cuenta de profesor',
                                  style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: buttonTextColor,
                                  ),
                                ),
                              ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya tienes cuenta? ',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          color: mutedTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          studentCtrl.authError.value = '';
                          teacherCtrl.authError.value = '';
                          Get.offAllNamed('/login');
                        },
                        child: Text(
                          'Inicia sesión',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}