import 'package:example/presentation/controllers/teacher/teacher_criteria_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_criteria_widgets.dart';

class TeacherCriteriaPage extends StatelessWidget {
  const TeacherCriteriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(CriteriaController());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            header("CRITERIOS"),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // INPUTS
                    Obx(() => Input(
                          hint: "Nombre",
                          value: ctrl.name.value,
                          onChanged: (v) => ctrl.name.value = v,
                        )),

                    const SizedBox(height: 10),

                    Obx(() => Input(
                          hint: "Descripción",
                          value: ctrl.description.value,
                          onChanged: (v) => ctrl.description.value = v,
                        )),

                    const SizedBox(height: 15),

                    // BOTÓN AÑADIR
                    GestureDetector(
                      onTap: ctrl.addCriterion,
                      child: mainButton("AÑADIR"),
                    ),

                    const SizedBox(height: 20),

                    // LISTA
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "CRITERIOS",
                        style: GoogleFonts.sora(fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Obx(() => Column(
                          children: ctrl.criteria
                              .asMap()
                              .entries
                              .map((entry) {
                            final i = entry.key;
                            final c = entry.value;

                            return ListTile(
                              title: Text(c['name'] ?? ''),
                              subtitle: Text(
                                c['description'] ?? '',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        ctrl.deleteCriterion(i),
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Get.toNamed(
                                  '/teacher/edit-criteria',
                                  arguments: {
                                    'index': i,
                                    'data': c,
                                  },
                                );
                              },
                            );
                          }).toList(),
                        )),
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