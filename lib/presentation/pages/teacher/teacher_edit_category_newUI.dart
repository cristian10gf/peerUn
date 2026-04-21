import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:example/domain/models/group_category.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_form_widgets.dart';

class TeacherEditCategoryNewUI extends StatefulWidget {
  const TeacherEditCategoryNewUI({super.key});

  @override
  State<TeacherEditCategoryNewUI> createState() =>
      _TeacherEditCategoryNewUIState();
}

class _TeacherEditCategoryNewUIState
    extends State<TeacherEditCategoryNewUI> {
  final TextEditingController nameCtrl = TextEditingController();
  late final GroupCategory category;

  @override
  void initState() {
    super.initState();
    // Load category from Get.arguments assuming navigation passed it
    category = Get.arguments as GroupCategory;
    nameCtrl.text = category.name;
  }

  // 🧪 MOCK DATA: Criterios por defecto (Esto también debería venir de una relación real si existe)
  final criteria = [
    "Participación",
    "Trabajo en equipo",
    "Claridad",
    "Creatividad",
  ];

  final selectedCriteria = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── HEADER ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.arrow_back),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "CATEGORÍA",
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📝 Nombre
                    InputCard(
                      hint: "Nombre",
                      value: nameCtrl.text,
                      onChanged: (v) { nameCtrl.text = v; },
                    ),

                    const SizedBox(height: 20),

                    // ── GRUPOS ─────────────────────────
                    Text(
                      "GRUPOS",
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: const Color(0xFF7B83EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Column(
                      children: category.groups.map((g) {
                        return GestureDetector(
                          onTap: () => _showGroupModal(context, g),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  g.name,
                                  style: GoogleFonts.sora(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  g.members.map((m) => m.name).join(', '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),                          ),
                        );                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── CRITERIOS ──────────────────────
                    Text(
                      "CRITERIOS",
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: const Color(0xFF7B83EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Column(
                      children: criteria.map((c) {
                        final selected = selectedCriteria.contains(c);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (selected) {
                                selectedCriteria.remove(c);
                              } else {
                                selectedCriteria.add(c);
                              }
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF7B83EB).withOpacity(0.1)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF7B83EB)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c,
                                    style: GoogleFonts.sora(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? const Color(0xFF7B83EB)
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 30),

                    // 💾 BOTÓN
                    GestureDetector(
                      onTap: () {
                        Get.back(); // por ahora solo regresa
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B83EB),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "GUARDAR",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupModal(BuildContext context, CourseGroup group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F4F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    group.name,
                    style: GoogleFonts.sora(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3140),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B83EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${group.members.length} miembros",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7B83EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Promedio General del Grupo: Sin datos",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "INTEGRANTES",
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: const Color(0xFF7B83EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...group.members.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF7B83EB).withValues(alpha: 0.1),
                        child: Text(
                          m.name.isNotEmpty ? m.name.substring(0, 1).toUpperCase() : '?',
                          style: const TextStyle(
                            color: Color(0xFF7B83EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              m.username,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sin nota
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Sin datos",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}