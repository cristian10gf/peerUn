import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TDashHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const TDashHeader({
    super.key,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final sessionCtrl = Get.find<TeacherSessionController>();

    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      child: Obx(() {
        final t = sessionCtrl.teacher.value;
        if (t == null) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel docente',
                    style: GoogleFonts.sora(
                      fontSize: 11,
                      color: tkTextFaint,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.name,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: tkText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [tkGold, Color(0xFFE3C26E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  t.initials,
                  style: GoogleFonts.dmMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: tkBackground,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}