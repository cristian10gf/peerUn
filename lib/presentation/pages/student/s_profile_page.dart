import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/controllers/student_controller.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:example/presentation/pages/student/widgets/student_bottom_nav.dart';

class SProfilePage extends StatelessWidget {
  const SProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StudentController>();

    return Scaffold(
      backgroundColor: skBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: skSurface,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Obx(() {
                final s = ctrl.student.value;
                if (s == null) return const SizedBox.shrink();
                return Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: skPrimaryLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.initials,
                        style: GoogleFonts.dmMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: skPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: GoogleFonts.sora(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: skText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.email,
                            style: GoogleFonts.dmMono(
                              fontSize: 11,
                              color: skTextFaint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ctrl.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 13,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Salir',
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 1, color: skBorder),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RESUMEN',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: skTextFaint,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: skSurface,
                        border: Border.all(color: skBorder),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Obx(() {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow(
                              label: 'Evaluaciones totales',
                              value: '${ctrl.evaluations.length}',
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Evaluaciones activas',
                              value: '${ctrl.activeEvaluations.length}',
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Promedio recibido',
                              value: ctrl.myAverage.toStringAsFixed(2),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            StudentBottomNav(activeIndex: 3),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: skTextMid,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmMono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: skPrimary,
          ),
        ),
      ],
    );
  }
}
