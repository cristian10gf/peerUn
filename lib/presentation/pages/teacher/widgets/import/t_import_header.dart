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
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 👤 Perfil + acción
          Row(
            children: [
              /// Avatar moderno (círculo)
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: tkGold,
                ),
                alignment: Alignment.center,
                child: Text(
                  teacher.initials,
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: tkBackground,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// Nombre + email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.name,
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

              const SizedBox(width: 8),

              /// Botón "Cursos" (pill moderna)
              GestureDetector(
                onTap: onCoursesTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: tkSurfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: tkGold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Cursos',
                        style: GoogleFonts.sora(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Importar grupos',
            style: GoogleFonts.sora(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tkText,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Desde archivo CSV de Brightspace',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: tkTextFaint,
            ),
          ),
        ],
      ),
    );
  }
}