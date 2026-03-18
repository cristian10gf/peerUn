import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/teacher_colors.dart';
import 'package:example/presentation/pages/teacher/teacher_controller.dart';

class TNewEvalPage extends StatelessWidget {
  const TNewEvalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TeacherController>();
    return Scaffold(
      backgroundColor: tkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: tkSurface,
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(label: 'Volver', route: '/teacher/dash'),
                  const SizedBox(height: 16),
                  Text('Nueva evaluación',
                      style: GoogleFonts.sora(
                        fontSize: 20, fontWeight: FontWeight.w800,
                        letterSpacing: -0.5, color: tkText,
                      )),
                ],
              ),
            ),
            const Divider(height: 1, color: tkBorder),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Nombre ──────────────────────────────────────────────
                    _SectionLabel('NOMBRE'),
                    const SizedBox(height: 8),
                    Obx(() => _GoldTextField(
                          value: ctrl.evalName.value,
                          onChanged: (v) => ctrl.evalName.value = v,
                        )),
                    const SizedBox(height: 18),

                    // ── Categoría ────────────────────────────────────────────
                    _SectionLabel('CATEGORÍA DE GRUPOS'),
                    const SizedBox(height: 8),
                    Obx(() {
                      final name = ctrl.selectedCategoryName.value;
                      final empty = ctrl.categories.isEmpty;
                      return GestureDetector(
                        onTap: empty
                            ? null
                            : () => _showCategoryPicker(context, ctrl),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 13),
                          decoration: BoxDecoration(
                            color: tkSurfaceAlt,
                            border: Border.all(color: tkBorder),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  empty
                                      ? 'Sin categorías importadas'
                                      : name.isEmpty
                                          ? 'Seleccionar categoría'
                                          : name,
                                  style: GoogleFonts.sora(
                                      fontSize: 13,
                                      color: (empty || name.isEmpty)
                                          ? tkTextFaint
                                          : tkTextMid),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  size: 16, color: tkTextFaint),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),

                    // ── Ventana de tiempo ────────────────────────────────────
                    _SectionLabel('VENTANA DE TIEMPO'),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          children: [24, 48, 72, 168].map((h) {
                            final selected = ctrl.selectedHours.value == h;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    right: h != 168 ? 6 : 0),
                                child: GestureDetector(
                                  onTap: () =>
                                      ctrl.selectedHours.value = h,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? tkGold
                                          : tkSurfaceAlt,
                                      border: Border.all(
                                          color: selected
                                              ? tkGold
                                              : tkBorder),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text('${h}h',
                                        style: GoogleFonts.dmMono(
                                          fontSize: 12,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected
                                              ? tkBackground
                                              : tkTextMid,
                                        )),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )),
                    const SizedBox(height: 18),

                    // ── Visibilidad ──────────────────────────────────────────
                    _SectionLabel('VISIBILIDAD DE RESULTADOS'),
                    const SizedBox(height: 8),
                    Obx(() => Column(
                          children: [
                            _VisibilityCard(
                              icon:        Icons.people_outline_rounded,
                              label:       'Pública',
                              description: 'Estudiantes ven sus promedios recibidos por criterio',
                              value:       'public',
                              selected:    ctrl.selectedVisibility.value == 'public',
                              onTap: () =>
                                  ctrl.selectedVisibility.value = 'public',
                            ),
                            const SizedBox(height: 8),
                            _VisibilityCard(
                              icon:        Icons.lock_outline_rounded,
                              label:       'Privada',
                              description: 'Solo el docente accede a los resultados detallados',
                              value:       'private',
                              selected:    ctrl.selectedVisibility.value == 'private',
                              onTap: () =>
                                  ctrl.selectedVisibility.value = 'private',
                            ),
                          ],
                        )),
                    const SizedBox(height: 20),

                    // ── Launch ───────────────────────────────────────────────
                    Obx(() {
                      if (ctrl.evalError.value.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            ctrl.evalError.value,
                            style: GoogleFonts.sora(
                                fontSize: 12,
                                color: const Color(0xFFEF4444)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() => GestureDetector(
                      onTap: ctrl.isLoading.value
                          ? null
                          : () => ctrl.createEvaluation(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: ctrl.isLoading.value
                              ? tkGold.withValues(alpha: 0.5)
                              : tkGold,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text('Lanzar evaluación',
                            style: GoogleFonts.sora(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: tkBackground,
                            )),
                      ),
                    )),
                    const SizedBox(height: 10),
                    Obx(() {
                      final name = ctrl.selectedCategoryName.value;
                      return Center(
                        child: Text(
                          name.isEmpty
                              ? 'Selecciona una categoría primero'
                              : 'Se notificará a todos los estudiantes de $name',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: tkTextFaint),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, TeacherController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: tkBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text('Categoría de grupos',
                    style: GoogleFonts.sora(
                      fontSize: 15, fontWeight: FontWeight.w700, color: tkText,
                    )),
              ),
              const SizedBox(height: 10),
              ...ctrl.categories.map((cat) {
                final selected = ctrl.selectedCategoryId.value == cat.id;
                return GestureDetector(
                  onTap: () {
                    ctrl.selectedCategoryId.value   = cat.id;
                    ctrl.selectedCategoryName.value = cat.name;
                    Get.back();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? tkGoldLight : tkSurface,
                      border: Border(
                        bottom: BorderSide(color: tkBorder),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.name,
                                  style: GoogleFonts.sora(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? tkGold : tkText,
                                  )),
                              Text(
                                '${cat.groupCount} grupos · ${cat.studentCount} estudiantes',
                                style: GoogleFonts.dmMono(
                                    fontSize: 11, color: tkTextFaint),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              size: 18, color: tkGold),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          )),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.sora(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: tkTextFaint, letterSpacing: 1.5,
        ));
  }
}

class _GoldTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _GoldTextField({required this.value, required this.onChanged});

  @override
  State<_GoldTextField> createState() => _GoldTextFieldState();
}

class _GoldTextFieldState extends State<_GoldTextField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged:  widget.onChanged,
      style: GoogleFonts.sora(
          fontSize: 14, fontWeight: FontWeight.w600, color: tkText),
      cursorColor: tkGold,
      decoration: InputDecoration(
        filled: true,
        fillColor: tkSurfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: tkGold.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: tkGold, width: 1.5),
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? tkGoldLight : tkSurface,
          border: Border.all(color: selected ? tkGold : tkBorder),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected ? tkGoldBorder : tkSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16,
                  color: selected ? tkGold : tkTextMid),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.sora(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: selected ? tkGold : tkText,
                      )),
                  const SizedBox(height: 2),
                  Text(description,
                      style: GoogleFonts.sora(
                          fontSize: 11, color: tkTextFaint)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final String label;
  final String route;
  const _BackButton({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.offNamed(route),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 12, 7),
        decoration: BoxDecoration(
          color: tkSurfaceAlt,
          border: Border.all(color: tkBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded,
                size: 14, color: tkTextMid),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.sora(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: tkTextMid,
                )),
          ],
        ),
      ),
    );
  }
}
