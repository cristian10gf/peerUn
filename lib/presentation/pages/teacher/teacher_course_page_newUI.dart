import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/presentation/controllers/teacher/teacher_course_import_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_evaluation_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/controllers/teacher/teacher_insights_controller.dart';
import 'package:example/presentation/models/teacher_data_insights_view_model.dart';

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
  final insightsCtrl = Get.find<TeacherInsightsController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Disparar siempre loadInsights para revalidar usando SWR en background
      insightsCtrl.loadInsights();
    });
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
            _header(courseId),
            _titleSection(),

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

// ── TITLE SECTION ─────────────────────────
  Widget _titleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => Text(
                courseCtrl.selectedCourseName.value,
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C3140),
                ),
              )),
          const SizedBox(height: 8),
          const Text(
            "En las calificaciones importan tus compañeros y profesores por que el feedback despues de perder una nota es importante y el agradecimiento despues de ganarla tambien.",
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF8E92A4),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────
Widget _header(int? courseId) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF3e3e50), // Color base según mockup
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          // Nubes de fondo (decorativas simples)
          Positioned(
            top: -20,
            right: -20,
            child: Icon(Icons.cloud, size: 100, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: 10,
            left: -10,
            child: Icon(Icons.cloud, size: 150, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -30,
            right: 50,
            child: Icon(Icons.cloud, size: 120, color: Colors.white.withValues(alpha: 0.05)),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
            child: Column(
              children: [
                // 🔙 Back / Edit Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: Icon(Icons.arrow_back, color: Colors.black87),   
                      ),
                    ),
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(Icons.edit_outlined, color: Colors.black87, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // ✨ REAL COURSE AVERAGE (From Insights)
                Obx(() {
                  if (insightsCtrl.isLoading.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 24.0),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  final vm = insightsCtrl.overviewVm;
                  double courseAvg = 0.0;
                  String avgLabel = "0.0";

                  if (vm != null && courseId != null) {
                    final strId = courseId.toString();
                    final match = vm.courseAverages.firstWhere(
                      (c) => c.courseId == strId,
                      orElse: () => const TeacherInsightsCourseAverageVm(
                        courseId: '', courseName: '', average: 0.0, sampleCount: 0, averageLabel: "N/A", sampleCountLabel: '',
                      ),
                    );
                    courseAvg = match.average;
                    avgLabel = match.averageLabel;
                  }

                  if (courseAvg > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          Text(
                            "Promedio del Curso",
                            style: GoogleFonts.sora(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            avgLabel,
                            style: GoogleFonts.sora(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const SizedBox(height: 12);
                  }
                }),
                
                // 📊 Progress Bars (Mockup data para criterios individuales no provistos agregados en DB)
                _buildCriteriaBar("Puntualidad", score: null),
                _buildCriteriaBar("Compromiso", score: null),
                _buildCriteriaBar("Actitud", score: null),
                _buildCriteriaBar("Participacion", score: null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBar(String label, {double? score}) {
    final bool hasData = score != null && score > 0;
    final double safeScore = score ?? 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Etiqueta
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),    
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Barra o "Sin datos"
          if (!hasData)
            const Expanded(
              child: Text(
                "Sin datos",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: safeScore / 5.0,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
          // Score Text
          if (hasData)
            Text(
              safeScore.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
    final resultsCtrl = Get.find<TeacherResultsController>();
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
                  onTap: () async {
                    await resultsCtrl.loadGroupResults(e);
                    Get.toNamed('/teacher/eval-results');
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
