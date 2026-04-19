import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InicioNewUI extends StatelessWidget {
  const InicioNewUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4), // gris claro
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Título superior
            const Text(
              "UniMejores",
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 2,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 40),

            // Imagen / ilustración
            Expanded(
              child: Center(
                child: Image.asset(
                  "assets/images/onboarding.png",
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Contenido inferior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Column(
                children: [
                  const Text(
                    "Califica a tu\nCompañero",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "En esta vida hay personas que\nse merecen feedback para\nmejorar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // navegación al nuevo login
                        Get.toNamed('/login_newUI');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B83EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "INICIAR SESIÓN",
                        style: TextStyle(
                          letterSpacing: 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}