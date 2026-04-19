import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/domain/models/auth_login_result.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/widgets/connectivity_floating_pill.dart';

class RegisterNewUI extends StatefulWidget {
  const RegisterNewUI({super.key});

  @override
  State<RegisterNewUI> createState() => _RegisterNewUIState();
}

class _RegisterNewUIState extends State<RegisterNewUI> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _localError;

  AppUserRole _selectedRole = AppUserRole.student;

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
    TeacherSessionController teacherCtrl,
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
      setState(() => _localError = 'Mínimo 6 caracteres');
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
    final teacherCtrl = Get.find<TeacherSessionController>();
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

              // 🧠 Ilustración
              Image.asset(
                "assets/images/onboarding.png",
                height: 120,
              ),

              const SizedBox(height: 20),

              // 📝 Título
              Text(
                "Por favor Regístrese",
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // 🟡 Botón Roble (visual)
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

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "O REGÍSTRESE CON EMAIL",
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              // 👤 Nombre
              _input("Nombre", _nameCtrl),

              const SizedBox(height: 10),

              // 📧 Email
              _input("Correo", _emailCtrl),

              const SizedBox(height: 10),

              // 🔒 Password
              _input(
                "Contraseña",
                _passwordCtrl,
                obscure: _obscurePass,
                toggle: () => setState(() => _obscurePass = !_obscurePass),
              ),

              const SizedBox(height: 10),

              // 🔒 Confirm
              _input(
                "Confirmar Contraseña",
                _confirmCtrl,
                obscure: _obscureConfirm,
                toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),

              const SizedBox(height: 10),

              // 🎭 Tipo de cuenta
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AppUserRole>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: AppUserRole.student,
                        child: Text("Estudiante"),
                      ),
                      DropdownMenuItem(
                        value: AppUserRole.teacher,
                        child: Text("Profesor"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRole = value);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ❌ errores
              if (_localError != null)
                Text(_localError!, style: const TextStyle(color: Colors.red)),

              Obx(() {
                final err = _selectedRole == AppUserRole.student
                    ? studentCtrl.authError.value
                    : teacherCtrl.authError.value;

                if (err.isEmpty) return const SizedBox();
                return Text(err, style: const TextStyle(color: Colors.red));
              }),

              const SizedBox(height: 20),

              // 🚀 botón
              Obx(() {
                final loading = _selectedRole == AppUserRole.student
                    ? studentCtrl.isLoading.value
                    : teacherCtrl.isLoading.value;

                final canAct = connectivityCtrl.isConnected.value;

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading || !canAct
                        ? null
                        : () => _submit(studentCtrl, teacherCtrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B83EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("REGISTRARSE"),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // 🔁 ir a login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("¿Ya tienes cuenta? "),
                  GestureDetector(
                    onTap: () {
                      studentCtrl.authError.value = '';
                      teacherCtrl.authError.value = '';
                      Get.offAllNamed('/login_newUI');
                    },
                    child: const Text(
                      "Inicia sesión",
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

  // 🔧 input reutilizable
  Widget _input(
    String hint,
    TextEditingController ctrl, {
    bool obscure = false,
    VoidCallback? toggle,
  }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: toggle,
              )
            : null,
      ),
    );
  }
}