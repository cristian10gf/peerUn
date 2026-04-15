import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/presentation/controllers/teacher/teacher_results_controller.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_detail_body.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_header.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_overview_body.dart';
import 'package:example/presentation/pages/teacher/widgets/results/teacher_results_state_cards.dart';
import 'package:example/presentation/theme/teacher_colors.dart';

class TResultsPage extends StatelessWidget {
  const TResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherResultsController>();

    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Obx(() {
              final detailVm = ctrl.selectedDetailVm;
              final isDrillDown = ctrl.selectedGroupIndex != null;
              final evalName = ctrl.selectedEval.value?.name ?? '-';

              return TeacherResultsHeader(
                backLabel: isDrillDown ? 'Grupos' : 'Volver',
                title: detailVm?.groupName ?? 'Resultados',
                subtitle:
                    '$evalName · ${isDrillDown ? 'Desglose completo' : 'Vista general'}',
                onBackTap: () {
                  if (isDrillDown) {
                    ctrl.closeGroupDetail();
                    return;
                  }
                  Get.offNamed('/teacher/dash');
                },
              );
            }),
            const Divider(height: 1, color: tkBorder),
            Expanded(
              child: Obx(() {
                if (ctrl.resultsLoading.value) {
                  return const TeacherResultsLoadingStateCard();
                }

                if (ctrl.resultsError.value.isNotEmpty) {
                  return TeacherResultsErrorStateCard(
                    message: ctrl.resultsError.value,
                  );
                }

                final detailVm = ctrl.selectedDetailVm;
                if (detailVm != null) {
                  return TeacherResultsDetailBody(vm: detailVm);
                }

                return TeacherResultsOverviewBody(
                  vm: ctrl.overviewVm,
                  onGroupTap: ctrl.openGroupDetail,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
