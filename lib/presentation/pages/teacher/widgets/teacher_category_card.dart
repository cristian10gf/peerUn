import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/domain/models/group_category.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherCategoryCard extends StatefulWidget {
  final GroupCategory category;
  final VoidCallback onDelete;

  const TeacherCategoryCard({
    super.key,
    required this.category,
    required this.onDelete,
  });

  @override
  State<TeacherCategoryCard> createState() => _TeacherCategoryCardState();
}

class _TeacherCategoryCardState extends State<TeacherCategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final date =
        '${category.importedAt.day}/${category.importedAt.month}/${category.importedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tkSurface,
        border: Border.all(color: tkBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: tkTextMid,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tkText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${category.groupCount} grupos · ${category.studentCount} estudiantes · $date',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: tkTextFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: tkDanger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: tkDanger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: tkBorder),
            ...category.groups.map((group) => _TeacherGroupRow(group: group)),
          ],
        ],
      ),
    );
  }
}

class _TeacherGroupRow extends StatelessWidget {
  final CourseGroup group;

  const _TeacherGroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, size: 14, color: tkGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.name,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tkText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${group.members.length} estudiantes',
                style: GoogleFonts.dmMono(fontSize: 10, color: tkTextFaint),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...group.members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 3),
              child: Text(
                _toTitleCase(member.name),
                style: GoogleFonts.sora(fontSize: 11, color: tkTextMid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String value) {
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
