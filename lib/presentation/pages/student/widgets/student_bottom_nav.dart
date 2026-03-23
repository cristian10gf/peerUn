import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/app_colors.dart';

class StudentBottomNav extends StatelessWidget {
  final int activeIndex;

  const StudentBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.home_rounded,
        label: 'Inicio',
        route: '/student/courses',
      ),
      _NavItem(
        icon: Icons.history_rounded,
        label: 'Historial',
        route: '/student/eval-list',
      ),
      _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Resultados',
        route: '/student/results',
      ),
      _NavItem(
        icon: Icons.person_outline_rounded,
        label: 'Perfil',
        route: null,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: skSurface,
        border: Border(top: BorderSide(color: skBorder)),
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
                if (item.route != null &&
                    !Get.currentRoute.endsWith(item.route!)) {
                  Get.offNamed(item.route!);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: isActive ? skPrimary : skTextFaint,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: GoogleFonts.sora(
                      fontSize: 9,
                      letterSpacing: 0.3,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? skPrimary : skTextFaint,
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
  final String? route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
