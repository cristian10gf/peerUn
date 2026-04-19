import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/login_controller.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/widgets/connectivity_floating_pill.dart';

class LoginNewUI extends StatefulWidget {
  const LoginNewUI({super.key});

  @override
  State<LoginNewUI> createState() => _LoginNewUIState();
}

class _LoginNewUIState extends State<LoginNewUI> {
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🔙 Back
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),

              const SizedBox(height: 10),

              // 🧠 Ilustración (opcional si luego quieres agregarla)
              Image.asset(
                "assets/images/onboarding.png",
                height: 120,
              ),

              const SizedBox(height: 20),

              // 📝 Título
              Text(
                "Bienvenido de Vuelta",
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // 🔐 Botón Roble (placeholder visual)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "CONTINUAR CON UNINORTE",
                  style: TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),

              // Divider
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "O INICIA SESIÓN CON EMAIL",
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // 📧 Email
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(
                  hintText: "Correo",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔒 Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ❌ Error
              Obx(() {
                final err = ctrl.authError.value;
                if (err.isEmpty) return const SizedBox();
                return Text(
                  err,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                );
              }),

              const SizedBox(height: 20),

              // 🚀 Botón login (MISMA LÓGICA)
              Obx(() {
                final loading = ctrl.isLoading.value;
                final canAct = connectivityCtrl.isConnected.value;

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading || !canAct
                        ? null
                        : () => ctrl.login(
                              _emailCtrl.text,
                              _passwordCtrl.text,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B83EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text("INICIA SESIÓN"),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // 🧾 Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿No tienes cuenta? "),
                  GestureDetector(
                    onTap: () {
                      ctrl.clearError();
                      Get.toNamed('/register_newUI');
                    },
                    child: const Text(
                      "Regístrate",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const ConnectivityFloatingPill(),
    );
  }
}