import 'package:example/presentation/controllers/teacher/teacher_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherBottomNav extends StatelessWidget {
  final int activeIndex;

  const TeacherBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(
        icon: Icons.home_rounded,
        label: "Inicio",
        route: '/teacher/dash',
      ),
      _NavItem(
        icon: Icons.bar_chart_rounded,
        label: "Reportes",
        route: '/teacher/results',
      ),
      _NavItem(
        icon: Icons.person_rounded,
        label: "Perfil",
        route: '/teacher/profile',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2), // sombra hacia arriba
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == activeIndex;

          final activeColor = const Color(0xFF7B83EB);

          return GestureDetector(
            onTap: () {
              if (item.route == '/teacher/profile') {
                _showProfile(context);
                return;
              }
              if (!Get.currentRoute.endsWith(item.route)) {
                Get.offNamed(item.route);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 24,
                  color: isActive ? activeColor : Colors.grey,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? activeColor : Colors.grey,
                  ),
                ),
              ],
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

void _showProfile(BuildContext context) {
  final sessionCtrl = Get.find<TeacherSessionController>();
  final teacher = sessionCtrl.teacher.value;
  if (teacher == null) return;

  showModalBottomSheet(
    context: context,
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(teacher.name),
          Text(teacher.email),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => sessionCtrl.logout(),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    ),
  );
}
