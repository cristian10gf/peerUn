import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controller
import 'package:example/presentation/controllers/student_controller.dart';

// Modelos
import 'package:example/domain/models/evaluation.dart';

// Utils
import 'package:collection/collection.dart';

// Widgets (si separas el bottom nav en otro archivo)
import 'package:example/presentation/pages/student/widgets/student_bottom_nav.dart';

class StudentHomeNewUI extends StatelessWidget {
  const StudentHomeNewUI({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<StudentController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── HEADER ─────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [Text("UniMejores")]),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Obx(() {
                if (ctrl.isLoadingHome.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (ctrl.homeCourses.isEmpty) {
                  return const Center(child: Text("No hay cursos"));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Con que materia quieres\nempezar?",
                        style: GoogleFonts.sora(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        "Elije la que te guste mas.",
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🔥 CURSOS
                      ...ctrl.homeCourses.map((course) {
                        final eval = ctrl.evaluations.firstWhereOrNull(
                          (e) => e.courseName == course.name && e.isActive,
                        );

                        return _studentCourseCard(
                          courseName: course.name,
                          evaluation: eval,
                          onTap: () {
                            if (eval != null && ctrl.canEvaluate(eval)) {
                              ctrl.selectEvalForEvaluation(eval);
                            }
                            // 👇 SIEMPRE navega
                            Get.toNamed(
                              '/student/course',
                              arguments: course.name,
                            );
                          },
                        );
                      }).toList(),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }),
            ),

            const StudentBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }
}

Widget _studentCourseCard({
  required String courseName,
  Evaluation? evaluation,
  required VoidCallback onTap,
}) {
  final hasEval = evaluation != null;

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B83EB), Color(0xFF9FA8FF)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            courseName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 8),

          if (hasEval) ...[
            Text(
              evaluation.name,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                "EVALUAR",
                style: TextStyle(
                  color: Color(0xFF7B83EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              "Sin evaluaciones activas",
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    ),
  );
}

class StudentBottomNav extends StatelessWidget {
  final int activeIndex;

  const StudentBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.home, "Inicio", '/student/home'),
      _NavItem(Icons.person, "Perfil", 'profile'),
    ];

    final ctrl = Get.find<StudentController>();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return GestureDetector(
            onTap: () {
              if (item.route == 'profile') {
                _showProfile(context, ctrl);
              } else {
                Get.offNamed(item.route);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: index == activeIndex
                      ? const Color(0xFF7B83EB)
                      : Colors.grey,
                ),
                Text(item.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showProfile(BuildContext context, StudentController ctrl) {
    final s = ctrl.student.value;
    if (s == null) return;

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.name),
            Text(s.email),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: ctrl.logout,
              child: const Text("Cerrar sesión"),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;

  _NavItem(this.icon, this.label, this.route);
}
