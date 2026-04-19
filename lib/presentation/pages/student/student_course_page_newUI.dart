import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// Controller
import 'package:example/presentation/controllers/student_controller.dart';

// Modelos
import 'package:example/domain/models/evaluation.dart';
import 'package:example/domain/models/peer_evaluation.dart';

class StudentCoursePage extends StatefulWidget {
  const StudentCoursePage({super.key});

  @override
  State<StudentCoursePage> createState() => _StudentCoursePageState();
}

class _StudentCoursePageState extends State<StudentCoursePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ctrl = Get.find<StudentController>();

  List<Evaluation> courseEvals = [];

  @override
  void initState() {
    super.initState();

    final courseName = Get.arguments as String;

    courseEvals = ctrl.evaluations
        .where((e) => e.courseName == courseName)
        .toList();

    _tabController = TabController(length: courseEvals.length, vsync: this);

    if (courseEvals.isNotEmpty) {
      ctrl.selectEvalForEvaluation(courseEvals[0]);
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;

      final eval = courseEvals[_tabController.index];
      ctrl.selectEvalForEvaluation(eval);
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseName = Get.arguments as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            _header(courseName),

            if (courseEvals.isEmpty)
              const Expanded(
                child: Center(child: Text("No hay evaluaciones")),
              )
            else ...[
              _tabs(),

              Expanded(
                child: Obx(() => _peersList()),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
Widget _header(String title) {
  return Container(
    height: 180,
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Color(0xFF4B4F63),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Stack(
      children: [
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
        Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
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

Widget _tabs() {
  return TabBar(
    controller: _tabController,
    isScrollable: true,
    indicatorColor: const Color(0xFF7B83EB),
    labelColor: const Color(0xFF7B83EB),
    unselectedLabelColor: Colors.grey,
    tabs: courseEvals
        .map((e) => Tab(text: e.name))
        .toList(),
  );
}


Widget _peersList() {
  if (ctrl.peers.isEmpty) {
    return const Center(child: Text("No hay compañeros"));
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: ctrl.peers.length,
    itemBuilder: (_, i) {
      final p = ctrl.peers[i];

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.black54),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                p.name,
                style: GoogleFonts.sora(fontWeight: FontWeight.w500),
              ),
            ),

            // 🔥 ESTADO
            _statusBadge(p),
          ],
        ),
      );
    },
  );
}

Widget _statusBadge(Peer p) {
  if (p.evaluated) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        "Calificado",
        style: TextStyle(color: Colors.green),
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      "Pendiente",
      style: TextStyle(color: Colors.orange),
    ),
  );
}
}
