import 'package:example/presentation/controllers/connectivity_controller.dart';
import 'package:example/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ConnectivityFloatingPill extends StatelessWidget {
  final double bottomSpacing;

  const ConnectivityFloatingPill({
    super.key,
    this.bottomSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    final connectivityCtrl = Get.find<ConnectivityController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final connected = connectivityCtrl.isConnected.value;
      final bgColor = connected
          ? (isDark ? const Color(0x1322C55E) : const Color(0xFFE7F8EF))
          : (isDark ? const Color(0x16EF4444) : const Color(0xFFFDEBEC));
      final borderColor = connected
          ? (isDark ? tkSuccess.withValues(alpha: 0.5) : const Color(0xFF9ADBB7))
          : (isDark ? tkDanger.withValues(alpha: 0.5) : const Color(0xFFF4A7AB));
      final textColor = connected
          ? (isDark ? tkSuccess : const Color(0xFF0F5D33))
          : (isDark ? tkDanger : const Color(0xFF8A1F2A));

      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSpacing),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 8),
                Text(
                  connectivityCtrl.shortStatusLabel,
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}