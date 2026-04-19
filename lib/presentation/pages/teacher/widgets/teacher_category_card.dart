import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherCategoryCard extends StatelessWidget {
  final GroupCategory category;
  final VoidCallback onDelete;

  const TeacherCategoryCard({
    super.key,
    required this.category,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🧠 HEADER (categoría)
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name.toUpperCase(),
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tkTextFaint,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: tkDanger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// 📋 LISTA DE GRUPOS
          ...category.groups.map((group) => _GroupRow(group: group)),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  final CourseGroup group;

  const _GroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tkSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          /// icono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tkGold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_rounded,
              size: 16,
              color: tkGold,
            ),
          ),

          const SizedBox(width: 12),

          /// info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group.members.length} estudiantes',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: tkTextFaint,
                  ),
                ),
              ],
            ),
          ),

          /// acción (opcional futura)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: tkTextFaint,
          ),
        ],
      ),
    );
  }
}