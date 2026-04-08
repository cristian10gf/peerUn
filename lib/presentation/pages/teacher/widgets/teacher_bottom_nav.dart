import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      _NavItem(icon: Icons.home_rounded, route: '/teacher/dash'),
      _NavItem(icon: Icons.rate_review_rounded, route: '/teacher/new-eval'),
      _NavItem(icon: Icons.bar_chart_rounded, route: '/teacher/results'),
      _NavItem(icon: Icons.upload_file_rounded, route: importRoute),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: tkSurface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = index == activeIndex;

            return GestureDetector(
              onTap: () {
                if (!Get.currentRoute.endsWith(item.route)) {
                  Get.offNamed(item.route);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isActive ? tkGold.withOpacity(0.15) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 22,
                  color: isActive ? tkGold : tkTextFaint,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String route;

  const _NavItem({
    required this.icon,
    required this.route,
  });
}