import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/student/student_controller.dart';
import 'package:example/presentation/widgets/auth_widgets.dart';

class SLoginPage extends StatefulWidget {
  const SLoginPage({super.key});

  @override
  State<SLoginPage> createState() => _SLoginPageState();
}

class _SLoginPageState extends State<SLoginPage> {
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
    final ctrl = Get.find<StudentController>();
    return Scaffold(
      backgroundColor: skBackground,
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
                    color: skPrimaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: skPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'PeerEval',
                  style: GoogleFonts.sora(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    letterSpacing: -0.8, color: skText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'STUDENT',
                  style: GoogleFonts.sora(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    letterSpacing: 3, color: skTextFaint,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email ──────────────────────────────────────────────────
                AppTextField(
                  controller:  _emailCtrl,
                  hint:        'Correo electrónico',
                  icon:        Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),

                // ── Password ───────────────────────────────────────────────
                AppTextField(
                  controller: _passwordCtrl,
                  hint:       'Contraseña',
                  icon:       Icons.lock_outline_rounded,
                  obscure:    _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18, color: skTextFaint,
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
                    child: Text(
                      err,
                      style: GoogleFonts.sora(
                          fontSize: 12, color: Colors.red.shade400),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),

                // ── Login button ───────────────────────────────────────────
                Obx(() => PrimaryButton(
                      label:   'Iniciar sesión',
                      loading: ctrl.isLoading.value,
                      onTap: () =>
                          ctrl.login(_emailCtrl.text, _passwordCtrl.text),
                    )),
                const SizedBox(height: 20),

                // ── Register link ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta? ',
                        style: GoogleFonts.sora(
                            fontSize: 12, color: skTextFaint)),
                    GestureDetector(
                      onTap: () {
                        ctrl.authError.value = '';
                        Get.toNamed('/student/register');
                      },
                      child: Text(
                        'Regístrate',
                        style: GoogleFonts.sora(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: skPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Autenticado por Roble SSO',
                    style: GoogleFonts.dmMono(fontSize: 11, color: skTextFaint),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ctrl.authError.value = '';
                      Get.offNamed('/teacher/login');
                    },
                    child: Text(
                      '¿Eres docente? Accede aquí →',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: skTextMid,
                        decoration: TextDecoration.underline,
                        decorationColor: skTextMid,
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
