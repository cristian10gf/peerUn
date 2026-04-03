import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentBackButton extends StatelessWidget {
  final String label;
  final String? route;

  const StudentBackButton({super.key, required this.label, this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route == null ? () => Get.back() : () => Get.offNamed(route!),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: skSurfaceAlt,
          border: Border.all(color: skBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded, size: 14, color: skTextMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: skTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
