import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';

class TeacherCoursePage extends StatefulWidget {
  const TeacherCoursePage({super.key});

  @override
  State<TeacherCoursePage> createState() => _TeacherCoursePageState();
}

class _TeacherCoursePageState extends State<TeacherCoursePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final courseCtrl = Get.find<TeacherCourseImportController>();
  final evalCtrl = Get.find<TeacherEvaluationController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final courseId = Get.arguments as int?;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ─────────────────────────────
            _header(),

            // ── BODY ───────────────────────────────
            Expanded(
              child: Obx(() {
                final hasCategories = courseCtrl.categoriesForCourse.isNotEmpty;
                final hasEvaluations = evalCtrl.evaluations.isNotEmpty;

                final hasData = hasCategories || hasEvaluations;

                if (!hasData) {
                  return _emptyImportState(courseId);
                }

                return Column(
                  children: [
                    _tabs(),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_evaluationsTab(), _categoriesTab()],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────
  Widget _header() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF4B4F63),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          // 🔙 Back
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          // ✏️ Edit (placeholder)
          Align(
            alignment: Alignment.topRight,
            child: const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.edit, color: Colors.white),
            ),
          ),

          // 📚 Title
          Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              courseCtrl.selectedCourseName.value,
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── EMPTY STATE (IMPORT) ──────────────────────
  Widget _emptyImportState(int? courseId) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF7B83EB),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.upload_file,
                  size: 40,
                  color: Color(0xFF7B83EB),
                ),
                const SizedBox(height: 10),

                Text(
                  "Importar desde Brightspace",
                  style: GoogleFonts.sora(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 6),

                const Text(
                  "CSV o JSON con categorías y grupos",
                  style: TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    Get.toNamed('/teacher/import', arguments: courseId);
                  },
                  child: const Text("Seleccionar archivo"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── TABS ─────────────────────────────────────
  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: const Color(0xFF7B83EB),
      labelColor: const Color(0xFF7B83EB),
      unselectedLabelColor: Colors.grey,
      tabs: const [
        Tab(text: "EVALUACIONES"),
        Tab(text: "CATEGORÍAS"),
      ],
    );
  }

  // ── EVALUATIONS TAB ──────────────────────────
  Widget _evaluationsTab() {
    return Obx(() {
      final categoryIds = courseCtrl.categoriesForCourse
          .map((c) => c.id)
          .toSet();

      final list = evalCtrl.evaluations
          .where((e) => categoryIds.contains(e.categoryId))
          .toList();

      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final e = list[i];

                return ListTile(
                  leading: const Icon(Icons.rate_review),
                  title: Text(e.name),
                  subtitle: Text(
                    "Cierra: ${e.closesAt.day}/${e.closesAt.month}/${e.closesAt.year}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Get.toNamed('/teacher/results');
                  },
                );
              },
            ),
          ),

          _bottomButton("CREAR UNA NUEVA EVALUACIÓN", () {
            Get.toNamed('/teacher/new-eval');
          }),
        ],
      );
    });
  }

  // ── CATEGORIES TAB ───────────────────────────
  Widget _categoriesTab() {
    final courseCtrl = Get.find<TeacherCourseImportController>();

    return Column(
      children: [
        // 📂 LISTA DE CATEGORÍAS
        Expanded(
          child: Obx(() {
            if (courseCtrl.categoriesForCourse.isEmpty) {
              return const Center(child: Text("No hay categorías"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: courseCtrl.categoriesForCourse.length,
              itemBuilder: (_, i) {
                final c = courseCtrl.categoriesForCourse[i];
                return GestureDetector(
                  onTap: () {
                    Get.toNamed('/teacher/edit-category', arguments: c);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
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

                        // 🗑️ eliminar
                        GestureDetector(
                          onTap: () => _confirmDeleteCategory(c.id),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ➡️ editar
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // 🔥 BOTÓN ABAJO (como evaluaciones)
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.toNamed('/teacher/new-category');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B83EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "CREAR UNA NUEVA CATEGORÍA",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── BOTÓN INFERIOR ───────────────────────────
  Widget _bottomButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7B83EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  void _confirmDeleteCategory(int id) {
    Get.defaultDialog(
      title: "Eliminar categoría",
      middleText: "¿Seguro que deseas eliminar esta categoría?",
      textConfirm: "Eliminar",
      textCancel: "Cancelar",
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.find<TeacherCourseImportController>().deleteCategory(id);
        Get.back();
      },
    );
  }
}
