import 'package:example/presentation/controllers/teacher/teacher_criteria_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/presentation/pages/teacher/widgets/teacher_criteria_widgets.dart';


class TeacherEditCriteriaPage extends StatelessWidget {
  const TeacherEditCriteriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CriteriaController>();

    final args = Get.arguments;
    final int index = args['index'];
    final Map<String, String> data = args['data'];

    ctrl.loadForEdit(data);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: SafeArea(
        child: Column(
          children: [
            header("EDITAR CRITERIO"),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Obx(() => Input(
                        hint: "Nombre",
                        value: ctrl.name.value,
                        onChanged: (v) => ctrl.name.value = v,
                      )),

                  const SizedBox(height: 10),

                  Obx(() => Input(
                        hint: "Descripción",
                        value: ctrl.description.value,
                        onChanged: (v) =>
                            ctrl.description.value = v,
                      )),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      ctrl.updateCriterion(index);
                      Get.back();
                    },
                    child: mainButton("GUARDAR"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}