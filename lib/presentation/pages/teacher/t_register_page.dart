import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';
import 'package:example/presentation/widgets/teacher_auth_widgets.dart';

class TRegisterPage extends StatefulWidget {
  const TRegisterPage({super.key});

  @override
  State<TRegisterPage> createState() => _TRegisterPageState();
}

class _TRegisterPageState extends State<TRegisterPage> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  String? _localError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit(TeacherController ctrl) {
    setState(() => _localError = null);
    ctrl.authError.value = '';

    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final confirm  = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _localError = 'Completa todos los campos');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _localError = 'Correo electrónico inválido');
      return;
    }
    if (password.length < 6) {
      setState(() =>
          _localError = 'La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Las contraseñas no coinciden');
      return;
    }
    ctrl.register(name, email, password);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherController>();
    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color:        tkGoldLight,
                    border:       Border.all(color: tkGoldBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color:        tkGold,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Crear cuenta',
                    style: GoogleFonts.sora(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      letterSpacing: -0.8, color: tkText,
                    )),
                const SizedBox(height: 4),
                Text('DOCENTE',
                    style: GoogleFonts.sora(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      letterSpacing: 3, color: tkTextFaint,
                    )),
                const SizedBox(height: 32),

                TeacherTextField(
                  controller:   _nameCtrl,
                  hint:         'Nombre completo',
                  icon:         Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 10),
                TeacherTextField(
                  controller:   _emailCtrl,
                  hint:         'Correo institucional',
                  icon:         Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                TeacherTextField(
                  controller: _passwordCtrl,
                  hint:       'Contraseña',
                  icon:       Icons.lock_outline_rounded,
                  obscure:    _obscurePass,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18, color: tkTextFaint,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 10),
                TeacherTextField(
                  controller: _confirmCtrl,
                  hint:       'Confirmar contraseña',
                  icon:       Icons.lock_outline_rounded,
                  obscure:    _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18, color: tkTextFaint,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 8),

                if (_localError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_localError!,
                        style: GoogleFonts.sora(
                            fontSize: 12, color: tkDanger),
                        textAlign: TextAlign.center),
                  ),
                Obx(() {
                  final err = ctrl.authError.value;
                  if (err.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err,
                        style: GoogleFonts.sora(
                            fontSize: 12, color: tkDanger),
                        textAlign: TextAlign.center),
                  );
                }),

                Obx(() => TeacherPrimaryButton(
                      label:   'Crear cuenta',
                      loading: ctrl.isLoading.value,
                      onTap:   () => _submit(ctrl),
                    )),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta? ',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: tkTextFaint)),
                    GestureDetector(
                      onTap: () {
                        ctrl.authError.value = '';
                        Get.back();
                      },
                      child: Text('Inicia sesión',
                          style: GoogleFonts.sora(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: tkGold,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
