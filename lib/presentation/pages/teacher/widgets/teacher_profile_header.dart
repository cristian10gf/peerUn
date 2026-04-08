import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherProfileHeader extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onLogout;

  const TeacherProfileHeader({
    super.key,
    required this.teacher,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [tkGold, Color(0xFFE3C26E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              teacher.initials,
              style: GoogleFonts.dmMono(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: tkBackground,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.name,
                  style: GoogleFonts.sora(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: tkText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  teacher.email,
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: tkTextFaint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: tkDanger.withValues(alpha: 0.1),
                border: Border.all(color: tkDanger.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: 13, color: tkDanger),
                  const SizedBox(width: 6),
                  Text(
                    'Salir',
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tkDanger,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}