import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/teacher.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TImportHeader extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onCoursesTap;

  const TImportHeader({
    super.key,
    required this.teacher,
    required this.onCoursesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: tkSurface,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCoursesTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tkGold.withValues(alpha: 0.1),
                    border: Border.all(color: tkGold.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school_rounded, size: 13, color: tkGold),
                      const SizedBox(width: 6),
                      Text(
                        'Cursos',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tkGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Importar grupos',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tkText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Desde archivo CSV de Brightspace',
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: tkTextFaint,
            ),
          ),
        ],
      ),
    );
  }
}
