import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentPeerScoreSubmitButton extends StatelessWidget {
  final StudentController ctrl;

  const StudentPeerScoreSubmitButton({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ready = ctrl.allCriteriaScored;
      return GestureDetector(
        onTap: ready
            ? () {
                ctrl.savePeerScore();
                Get.offNamed('/student/peers');
              }
            : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: ready ? skPrimary : skBorder,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(
            ready ? 'Guardar y continuar' : 'Completa los 4 criterios',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: ready ? Colors.white : skTextFaint,
            ),
          ),
        ),
      );
    });
  }
}
