import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/controllers/login_controller.dart';
import 'package:example/presentation/pages/auth/widgets/auth_field.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/widgets/connectivity_floating_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LoginController>();
    final connectivityCtrl = Get.find<ConnectivityController>();
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    border: isDark ? Border.all(color: tkGoldBorder) : null,
                                  ),
                                  child: Icon(
                                    Icons.school_rounded,
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
                              'Bienvenido a EvalUn',
                              style: GoogleFonts.sora(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AuthField(
                              controller: _emailCtrl,
                              hint: 'Correo institucional',
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
                              obscure: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: mutedTextColor,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(() {
                              final err = ctrl.authError.value;
                              if (err.isEmpty) return const SizedBox(height: 8);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  err,
                                  style: GoogleFonts.sora(fontSize: 12, color: errorColor),
                                ),
                              );
                            }),
                            Obx(() {
                              final canAct = connectivityCtrl.isConnected.value;
                              final loading = ctrl.isLoading.value;

                              return GestureDetector(
                                onTap: loading || !canAct
                                    ? null
                                    : () => ctrl.login(
                                          _emailCtrl.text,
                                          _passwordCtrl.text,
                                        ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: (loading || !canAct)
                                        ? accentColor.withValues(alpha: 0.45)
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
                                      : Text(
                                          'Iniciar sesión',
                                          style: GoogleFonts.sora(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: buttonTextColor,
                                          ),
                                        ),
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                '¿No tienes cuenta?',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  color: mutedTextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                ctrl.clearError();
                                Get.toNamed('/register');
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                foregroundColor: textColor,
                                minimumSize: const Size(double.infinity, 44),
                              ),
                              child: Text(
                                'Crear cuenta',
                                style: GoogleFonts.sora(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                'Autenticado por Roble SSO',
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  color: mutedTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const ConnectivityFloatingPill(),
    );
  }
}
