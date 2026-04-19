import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // 🧪 MOCK DATA (luego backend)
  final groups = [
    {"name": "GRUPO 1", "students": "Jorge Sanchez, Cristian Gonzalez"},
    {"name": "GRUPO 2", "students": "Felipe Anguloes, Sandro Torres"},
  ];

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
                      value: "",
                      onChanged: (v) {},
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
                      children: groups.map((g) {
                        return Container(
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
                                g["name"]!,
                                style: GoogleFonts.sora(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                g["students"]!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
}