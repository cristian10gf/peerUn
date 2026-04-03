import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherBackButton extends StatelessWidget {
  final String label;
  final String? route;
  final VoidCallback? onTap;

  const TeacherBackButton({
    super.key,
    required this.label,
    this.route,
    this.onTap,
  }) : assert(route != null || onTap != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.offNamed(route!),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: tkSurfaceAlt,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded, size: 14, color: tkTextMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tkTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
