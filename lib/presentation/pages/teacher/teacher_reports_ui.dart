import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_bottom_nav.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_eval_card.dart';

class TeacherReportsUI extends StatefulWidget {
  const TeacherReportsUI({super.key});

  @override
  State<TeacherReportsUI> createState() => _TeacherReportsUIState();
}

class _TeacherReportsUIState extends State<TeacherReportsUI>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final courseCtrl = Get.find<TeacherCourseImportController>();
  final evalCtrl = Get.find<TeacherEvaluationController>();
  final resultsCtrl = Get.find<TeacherResultsController>();

@override
void initState() {
  super.initState();

  _tabController = TabController(
    length: courseCtrl.courses.length,
    vsync: this,
  );

  // 🔥 Cargar el primer curso automáticamente
  if (courseCtrl.courses.isNotEmpty) {
    courseCtrl.loadCategoriesForCourse(courseCtrl.courses[0].id);
  }

  // 🔥 Escuchar cambio de tab
  _tabController.addListener(() {
    if (_tabController.indexIsChanging) {
      final selectedCourse = courseCtrl.courses[_tabController.index];
      courseCtrl.loadCategoriesForCourse(selectedCourse.id);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── HEADER ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Analiza las actividades\nde tus cursos",
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── GRÁFICA (PLACEHOLDER) ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    "Gráfica próximamente",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── TABS DE CURSOS ─────────────────────
            Obx(() {
              if (courseCtrl.courses.isEmpty) {
                return const Text("No hay cursos");
              }

              return TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF7B83EB),
                labelColor: const Color(0xFF7B83EB),
                unselectedLabelColor: Colors.grey,
                tabs: courseCtrl.courses
                    .map((c) => Tab(text: c.name.toUpperCase()))
                    .toList(),
              );
            }),

            // ── CONTENIDO ─────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: courseCtrl.courses.map((course) {
                  return _categoriesList(course.id);
                }).toList(),
              ),
            ),
          ],
        ),
      ),

      // ── NAVBAR ────────────────────────────────
      bottomNavigationBar: const TeacherBottomNav(activeIndex: 1),
    );
  }

  // ── LISTA DE CATEGORÍAS POR CURSO ───────────
  Widget _categoriesList(int courseId) {
    return Obx(() {
      final categories = courseCtrl.categoriesForCourse;

      if (categories.isEmpty) {
        return const Center(child: Text("Sin categorías"));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final c = categories[i];
          final catEvals = evalCtrl.evaluations.where((e) => e.categoryId == c.id).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                title: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.black54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: GoogleFonts.sora(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "${c.groupCount} grupos",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Icon(Icons.arrow_drop_down, size: 18),
                ),
                children: [
                  if (catEvals.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        "No hay evaluaciones para esta categoría",
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                      child: Column(
                        children: catEvals.map((e) => TEvalCard(
                          eval: e,
                          resultsCtrl: resultsCtrl,
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}