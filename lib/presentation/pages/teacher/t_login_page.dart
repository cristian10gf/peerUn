import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';
import 'package:example/presentation/widgets/teacher_auth_widgets.dart';

class TLoginPage extends StatefulWidget {
  const TLoginPage({super.key});

  @override
  State<TLoginPage> createState() => _TLoginPageState();
}

class _TLoginPageState extends State<TLoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure       = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
                Text(
                  'EvalUn',
                  style: GoogleFonts.sora(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    letterSpacing: -0.8, color: tkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TEACHER',
                  style: GoogleFonts.sora(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    letterSpacing: 3, color: tkTextFaint,
                  ),
                ),
                const SizedBox(height: 32),

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
                  obscure:    _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18, color: tkTextFaint,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Error ──────────────────────────────────────────────────
                Obx(() {
                  final err = ctrl.authError.value;
                  if (err.isEmpty) return const SizedBox(height: 8);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(err,
                        style: GoogleFonts.sora(
                            fontSize: 12, color: tkDanger),
                        textAlign: TextAlign.center),
                  );
                }),

                Obx(() => TeacherPrimaryButton(
                      label:   'Iniciar sesión',
                      loading: ctrl.isLoading.value,
                      onTap: () =>
                          ctrl.login(_emailCtrl.text, _passwordCtrl.text),
                    )),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta? ',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: tkTextFaint)),
                    GestureDetector(
                      onTap: () {
                        ctrl.authError.value = '';
                        Get.toNamed('/teacher/register');
                      },
                      child: Text('Regístrate',
                          style: GoogleFonts.sora(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: tkGold,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Center(
                  child: Text('Autenticado por Roble SSO',
                      style: GoogleFonts.dmMono(
                          fontSize: 11, color: tkTextFaint)),
                ),
                const SizedBox(height: 24),

                // ── Toggle a estudiante ────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Get.offNamed('/student/login'),
                    child: Text(
                      '← Acceder como estudiante',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: tkTextMid,
                        decoration: TextDecoration.underline,
                        decorationColor: tkTextMid,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
