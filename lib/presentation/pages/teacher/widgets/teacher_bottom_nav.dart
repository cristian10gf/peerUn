import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TeacherBottomNav extends StatelessWidget {
  final int activeIndex;
  final String importRoute;

  const TeacherBottomNav({
    super.key,
    required this.activeIndex,
    this.importRoute = '/teacher/import',
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.home_rounded,
        label: 'INICIO',
        route: '/teacher/dash',
      ),
      _NavItem(
        icon: Icons.rate_review_rounded,
        label: 'EVALUAR',
        route: '/teacher/new-eval',
      ),
      _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'DATOS',
        route: '/teacher/data-insights',
      ),
      _NavItem(
        icon: Icons.upload_file_rounded,
        label: 'IMPORTAR',
        route: importRoute,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: tkSurface,
        border: Border(top: BorderSide(color: tkBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final isActive = entry.key == activeIndex;
          final item = entry.value;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (entry.key == activeIndex) {
                  return;
                }

                final currentRouteName = ModalRoute.of(context)?.settings.name;
                if (currentRouteName == item.route) {
                  return;
                }

                Get.offNamed(item.route);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: isActive ? tkGold : tkTextFaint,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      letterSpacing: 0.3,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? tkGold : tkTextFaint,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
