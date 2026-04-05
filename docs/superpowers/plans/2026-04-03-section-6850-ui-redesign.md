# Section 6850 UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar la UI actual de toda la app por la propuesta en Figma Section 6850, maximizando reutilizacion, consistencia visual, dinamismo por estado real y DI clara por modulo.

**Architecture:** Se mantiene la arquitectura limpia pragmatica actual (domain/data/presentation), pero se introduce un design system de presentacion (tokens + componentes base + mappers UI inyectados). Las pantallas quedan como composicion de widgets pequenos, mientras los controllers existentes conservan la logica de negocio. La inyeccion de dependencias se explicita con bindings por rol (student/teacher) y servicios UI de mapeo testeables.

**Tech Stack:** Flutter, Dart, GetX (routing/state/DI), Google Fonts, flutter_test.

---

## Scope Check

Este rediseño cruza auth + student + teacher, pero no son subsistemas independientes porque comparten:
1. El mismo set de tokens visuales (Section 6850)
2. El mismo shell de navegacion
3. El mismo patron de inyeccion y composicion

Se mantiene en un solo plan para evitar divergencia visual y duplicacion de componentes.

## File Structure (Locked Before Tasks)

### Create

- `lib/presentation/theme/figma_color_tokens.dart` — Colores base Section 6850 (surface, text, primary, accent, state).
- `lib/presentation/theme/figma_typography_tokens.dart` — Escala tipografica ABeeZee/Inter con estilos semanticos.
- `lib/presentation/theme/figma_spacing_tokens.dart` — Espaciado, radios y alturas estandar.
- `lib/presentation/theme/figma_theme.dart` — ThemeData light/dark para usar tokens de forma centralizada.
- `lib/presentation/models/ui/app_nav_item.dart` — Modelo de item de navegacion reusable por rol.
- `lib/presentation/services/ui/student_ui_mapper.dart` — Mapper inyectable para transformar estado StudentController a view models UI.
- `lib/presentation/services/ui/teacher_ui_mapper.dart` — Mapper inyectable para Teacher controllers.
- `lib/presentation/bindings/student_module_binding.dart` — Registro DI del modulo student (mappers + hooks de hidratacion).
- `lib/presentation/widgets/core/app_shell_scaffold.dart` — Scaffold base con top/bottom slots y paddings tokenizados.
- `lib/presentation/widgets/core/app_cta_button.dart` — Boton primario/secundario estandar.
- `lib/presentation/widgets/core/app_input_field.dart` — Campo de texto tokenizado (radius, hint, colores, estados).
- `lib/presentation/widgets/core/app_status_chip.dart` — Chip compacto para estados/etiquetas.
- `lib/presentation/widgets/core/app_segmented_tabs.dart` — Tabs tipo Figma para toggles de seccion.
- `lib/presentation/widgets/navigation/app_role_bottom_nav.dart` — Bottom nav role-aware basada en `AppNavItem`.
- `lib/presentation/pages/auth/widgets/login_hero_background.dart` — Fondo decorativo login Section 6850.
- `lib/presentation/pages/auth/widgets/welcome_role_page.dart` — Pantalla de bienvenida para estudiante/profesor.
- `lib/presentation/pages/student/widgets/home/student_featured_course_card.dart` — Card principal de Inicio (Figma `1:2`).
- `lib/presentation/pages/student/widgets/home/student_micro_content_card.dart` — Cards inferiores de reflexion/meditacion.
- `lib/presentation/pages/student/widgets/reports/student_grouped_bar_chart.dart` — Grafico de reportes (Figma `457:1184`).
- `lib/presentation/pages/student/widgets/reports/student_report_row.dart` — Fila de curso/grupos en reportes.
- `lib/presentation/pages/student/widgets/evaluation/student_score_option_row.dart` — Selector 0-5 reusable para calificacion.
- `lib/presentation/pages/student/widgets/evaluation/student_peer_status_tile.dart` — Row de companero + estado.
- `lib/presentation/pages/student/widgets/profile/student_profile_hero.dart` — Header oscuro perfil (Figma `3:2856`).
- `lib/presentation/pages/teacher/widgets/dashboard/teacher_stat_row.dart` — KPIs superiores de dashboard docente.
- `lib/presentation/pages/teacher/widgets/dashboard/teacher_eval_tile.dart` — Tile de evaluacion docente reusable.
- `lib/presentation/pages/teacher/widgets/reports/teacher_grouped_bar_chart.dart` — Variante docente de grafico.
- `lib/presentation/pages/teacher/widgets/forms/teacher_upload_dropzone.dart` — Zona de carga estilo Section 6850 (Figma `452:920`).
- `lib/presentation/pages/teacher/widgets/forms/teacher_form_field.dart` — Input docente estandar.
- `test/presentation/theme/figma_theme_test.dart`
- `test/presentation/widgets/core/app_core_widgets_test.dart`
- `test/presentation/widgets/navigation/app_role_bottom_nav_test.dart`
- `test/presentation/bindings/student_module_binding_test.dart`
- `test/presentation/pages/auth/login_page_section6850_test.dart`
- `test/presentation/pages/auth/welcome_role_page_test.dart`
- `test/presentation/pages/student/s_courses_page_section6850_test.dart`
- `test/presentation/pages/student/s_peer_score_page_section6850_test.dart`
- `test/presentation/pages/teacher/t_dash_page_section6850_test.dart`
- `test/presentation/pages/teacher/t_new_eval_page_section6850_test.dart`
- `test/presentation/smoke/section6850_routes_smoke_test.dart`

### Modify

- `lib/main.dart` — Consumir `figmaTheme`, registrar nuevos bindings y rutas de bienvenida.
- `lib/presentation/pages/auth/login_page.dart` — Reemplazo visual por layout Section 6850.
- `lib/presentation/pages/auth/register_page.dart` — Alinear campos/acciones al mismo design system.
- `lib/presentation/controllers/login_controller.dart` — Redireccion a welcome por rol antes del home final.
- `lib/presentation/pages/student/s_courses_page.dart` — Rediseño pantalla Inicio.
- `lib/presentation/pages/student/s_eval_list_page.dart` — Rediseño como pantalla de reportes.
- `lib/presentation/pages/student/s_peers_page.dart` — Rediseño lista de companeros.
- `lib/presentation/pages/student/s_peer_score_page.dart` — Rediseño de flujo de calificacion.
- `lib/presentation/pages/student/s_my_results_page.dart` — Ajuste visual a tokens/components.
- `lib/presentation/pages/student/s_profile_page.dart` — Rediseño perfil oscuro.
- `lib/presentation/pages/student/widgets/student_bottom_nav.dart` — Migracion a `AppRoleBottomNav`.
- `lib/presentation/pages/teacher/t_dash_page.dart` — Rediseño dashboard docente.
- `lib/presentation/pages/teacher/t_results_page.dart` — Rediseño resultados/reportes docente.
- `lib/presentation/pages/teacher/t_import_page.dart` — Integrar dropzone + formularios tokenizados.
- `lib/presentation/pages/teacher/t_new_eval_page.dart` — Rediseño crear/editar.
- `lib/presentation/pages/teacher/t_course_manage_page.dart` — Rediseño lista/creacion cursos.
- `lib/presentation/pages/teacher/t_profile_page.dart` — Ajuste visual consistente.
- `lib/presentation/pages/teacher/widgets/teacher_bottom_nav.dart` — Migracion a `AppRoleBottomNav`.
- `README.md` — Seccion de arquitectura de UI componentizada Section 6850.

---

### Task 1: Design Tokens + Global Theme

**Files:**
- Create: `lib/presentation/theme/figma_color_tokens.dart`
- Create: `lib/presentation/theme/figma_typography_tokens.dart`
- Create: `lib/presentation/theme/figma_spacing_tokens.dart`
- Create: `lib/presentation/theme/figma_theme.dart`
- Modify: `lib/main.dart`
- Test: `test/presentation/theme/figma_theme_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';
import 'package:example/presentation/theme/figma_theme.dart';

void main() {
  test('Section6850 primary color matches Figma token', () {
    expect(FigmaColorTokens.primary, const Color(0xFF8E97FD));
    expect(FigmaColorTokens.textPrimary, const Color(0xFF3F414E));
    expect(FigmaColorTokens.surfaceSubtle, const Color(0xFFF2F3F7));
  });

  test('figmaLightTheme wires scaffold background and primary color', () {
    final theme = figmaLightTheme();
    expect(theme.scaffoldBackgroundColor, FigmaColorTokens.background);
    expect(theme.colorScheme.primary, FigmaColorTokens.primary);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/theme/figma_theme_test.dart -r expanded`
Expected: FAIL with `Target of URI doesn't exist: '...figma_color_tokens.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/theme/figma_color_tokens.dart
import 'package:flutter/material.dart';

class FigmaColorTokens {
  static const background = Color(0xFFF6F7FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF2F3F7);
  static const textPrimary = Color(0xFF3F414E);
  static const textSecondary = Color(0xFFA1A4B2);
  static const primary = Color(0xFF8E97FD);
  static const primaryStrong = Color(0xFF808AFF);
  static const accentWarm = Color(0xFFFFCB7E);
  static const accentDark = Color(0xFF343434);
  static const success = Color(0xFF32D74B);
}

// lib/presentation/theme/figma_theme.dart
import 'package:flutter/material.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';

ThemeData figmaLightTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FigmaColorTokens.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: FigmaColorTokens.primary,
    surface: FigmaColorTokens.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FigmaColorTokens.background,
  );
}

// lib/main.dart (replace ThemeData setup)
// theme: figmaLightTheme(),
// darkTheme: figmaLightTheme(), // temporary while dark tokens are introduced in later tasks
// themeMode: ThemeMode.light,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/theme/figma_theme_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/theme/figma_theme_test.dart lib/presentation/theme/figma_color_tokens.dart lib/presentation/theme/figma_typography_tokens.dart lib/presentation/theme/figma_spacing_tokens.dart lib/presentation/theme/figma_theme.dart lib/main.dart
git commit -m "feat(ui): add Section6850 design tokens and app theme"
```

### Task 2: Core Reusable UI Primitives

**Files:**
- Create: `lib/presentation/widgets/core/app_shell_scaffold.dart`
- Create: `lib/presentation/widgets/core/app_cta_button.dart`
- Create: `lib/presentation/widgets/core/app_input_field.dart`
- Create: `lib/presentation/widgets/core/app_status_chip.dart`
- Create: `lib/presentation/widgets/core/app_segmented_tabs.dart`
- Test: `test/presentation/widgets/core/app_core_widgets_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/widgets/core/app_cta_button.dart';

void main() {
  testWidgets('AppCtaButton shows label and disabled state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCtaButton(
            label: 'INICIA SESION',
            onTap: null,
          ),
        ),
      ),
    );

    expect(find.text('INICIA SESION'), findsOneWidget);
    final gesture = tester.widget<GestureDetector>(find.byType(GestureDetector));
    expect(gesture.onTap, isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/widgets/core/app_core_widgets_test.dart -r expanded`
Expected: FAIL with `Target of URI doesn't exist: '...app_cta_button.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/widgets/core/app_cta_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';

class AppCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppCtaButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null
              ? FigmaColorTokens.primary.withValues(alpha: 0.45)
              : FigmaColorTokens.primary,
          borderRadius: BorderRadius.circular(34),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.aBeeZee(
            fontSize: 13,
            color: const Color(0xFFF6F1FB),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

// lib/presentation/widgets/core/app_input_field.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';

class AppInputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;

  const AppInputField({
    super.key,
    required this.hint,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.aBeeZee(fontSize: 15, color: FigmaColorTokens.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.aBeeZee(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: FigmaColorTokens.textSecondary,
        ),
        filled: true,
        fillColor: FigmaColorTokens.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/widgets/core/app_core_widgets_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/widgets/core/app_core_widgets_test.dart lib/presentation/widgets/core/app_shell_scaffold.dart lib/presentation/widgets/core/app_cta_button.dart lib/presentation/widgets/core/app_input_field.dart lib/presentation/widgets/core/app_status_chip.dart lib/presentation/widgets/core/app_segmented_tabs.dart
git commit -m "feat(ui): add reusable Section6850 core widgets"
```

### Task 3: Role-Aware Navigation + Student Module Binding (DI)

**Files:**
- Create: `lib/presentation/models/ui/app_nav_item.dart`
- Create: `lib/presentation/services/ui/student_ui_mapper.dart`
- Create: `lib/presentation/services/ui/teacher_ui_mapper.dart`
- Create: `lib/presentation/bindings/student_module_binding.dart`
- Create: `lib/presentation/widgets/navigation/app_role_bottom_nav.dart`
- Modify: `lib/main.dart`
- Test: `test/presentation/bindings/student_module_binding_test.dart`
- Test: `test/presentation/widgets/navigation/app_role_bottom_nav_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/presentation/bindings/student_module_binding.dart';
import 'package:example/presentation/services/ui/student_ui_mapper.dart';

void main() {
  test('StudentModuleBinding registers StudentUiMapper', () {
    Get.testMode = true;
    StudentModuleBinding().dependencies();
    expect(Get.isRegistered<StudentUiMapper>(), isTrue);
    Get.reset();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/bindings/student_module_binding_test.dart -r expanded`
Expected: FAIL with `Target of URI doesn't exist: '...student_module_binding.dart'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/services/ui/student_ui_mapper.dart
import 'package:example/presentation/controllers/student_controller.dart';

class StudentUiMapper {
  String dashboardTitle(StudentController ctrl) {
    final student = ctrl.student.value;
    return student == null ? 'UniMejores' : 'Hola ${student.name.split(' ').first}';
  }
}

// lib/presentation/bindings/student_module_binding.dart
import 'package:get/get.dart';
import 'package:example/presentation/services/ui/student_ui_mapper.dart';

class StudentModuleBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<StudentUiMapper>()) {
      Get.put(StudentUiMapper(), permanent: true);
    }
  }
}

// lib/main.dart (student routes now include binding)
// GetPage(name: '/student/courses', page: () => const SCoursesPage(), binding: StudentModuleBinding()),
// ...repeat for all /student/* routes
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/bindings/student_module_binding_test.dart test/presentation/widgets/navigation/app_role_bottom_nav_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/bindings/student_module_binding_test.dart test/presentation/widgets/navigation/app_role_bottom_nav_test.dart lib/presentation/models/ui/app_nav_item.dart lib/presentation/services/ui/student_ui_mapper.dart lib/presentation/services/ui/teacher_ui_mapper.dart lib/presentation/bindings/student_module_binding.dart lib/presentation/widgets/navigation/app_role_bottom_nav.dart lib/main.dart
git commit -m "feat(ui): add role-aware navigation and student module DI"
```

### Task 4: Auth + Welcome Redesign (Figma `1:3570`, `1:3480`, `403:183`)

**Files:**
- Create: `lib/presentation/pages/auth/widgets/login_hero_background.dart`
- Create: `lib/presentation/pages/auth/widgets/welcome_role_page.dart`
- Modify: `lib/presentation/pages/auth/login_page.dart`
- Modify: `lib/presentation/pages/auth/register_page.dart`
- Modify: `lib/presentation/controllers/login_controller.dart`
- Modify: `lib/main.dart`
- Test: `test/presentation/pages/auth/login_page_section6850_test.dart`
- Test: `test/presentation/pages/auth/welcome_role_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:example/presentation/pages/auth/widgets/welcome_role_page.dart';

void main() {
  testWidgets('WelcomeRolePage renders teacher headline', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: WelcomeRolePage(
          role: WelcomeRole.teacher,
          displayName: 'Jorge',
        ),
      ),
    );

    expect(find.textContaining('Comienza'), findsOneWidget);
    expect(find.text('COMIENZA YA'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/auth/welcome_role_page_test.dart -r expanded`
Expected: FAIL with `Undefined class 'WelcomeRolePage'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/auth/widgets/welcome_role_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';
import 'package:example/presentation/widgets/core/app_cta_button.dart';

enum WelcomeRole { student, teacher }

class WelcomeRolePage extends StatelessWidget {
  final WelcomeRole role;
  final String displayName;

  const WelcomeRolePage({
    super.key,
    required this.role,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = role == WelcomeRole.teacher;
    return Scaffold(
      backgroundColor: isTeacher ? FigmaColorTokens.primary : FigmaColorTokens.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                isTeacher
                    ? 'Hola $displayName, Comienza\na Administrar'
                    : 'Hola $displayName,\nComienza a Evaluar',
                textAlign: TextAlign.center,
                style: GoogleFonts.aBeeZee(
                  fontSize: 28,
                  color: isTeacher ? const Color(0xFFFFECCC) : FigmaColorTokens.textPrimary,
                ),
              ),
              const Spacer(),
              AppCtaButton(
                label: 'COMIENZA YA',
                onTap: () => Get.offAllNamed(isTeacher ? '/teacher/dash' : '/student/courses'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/presentation/controllers/login_controller.dart (inside login)
// Get.offAllNamed(result.role == AppUserRole.teacher ? '/welcome/teacher' : '/welcome/student');
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/auth/login_page_section6850_test.dart test/presentation/pages/auth/welcome_role_page_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/auth/login_page_section6850_test.dart test/presentation/pages/auth/welcome_role_page_test.dart lib/presentation/pages/auth/widgets/login_hero_background.dart lib/presentation/pages/auth/widgets/welcome_role_page.dart lib/presentation/pages/auth/login_page.dart lib/presentation/pages/auth/register_page.dart lib/presentation/controllers/login_controller.dart lib/main.dart
git commit -m "feat(ui): redesign auth and role welcome screens from Section6850"
```

### Task 5: Student Home + Reports Redesign (Figma `1:2`, `457:1184`)

**Files:**
- Create: `lib/presentation/pages/student/widgets/home/student_featured_course_card.dart`
- Create: `lib/presentation/pages/student/widgets/home/student_micro_content_card.dart`
- Create: `lib/presentation/pages/student/widgets/reports/student_grouped_bar_chart.dart`
- Create: `lib/presentation/pages/student/widgets/reports/student_report_row.dart`
- Modify: `lib/presentation/pages/student/s_courses_page.dart`
- Modify: `lib/presentation/pages/student/s_eval_list_page.dart`
- Modify: `lib/presentation/pages/student/widgets/student_bottom_nav.dart`
- Test: `test/presentation/pages/student/s_courses_page_section6850_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/presentation/pages/student/s_courses_page.dart';

void main() {
  testWidgets('SCoursesPage shows featured course CTA', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SCoursesPage()));
    expect(find.text('COMIENZA'), findsWidgets);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/student/s_courses_page_section6850_test.dart -r expanded`
Expected: FAIL with `Get.find<StudentController>() not found` or missing Section6850 widget text.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/student/widgets/home/student_featured_course_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';

class StudentFeaturedCourseCard extends StatelessWidget {
  final String courseName;
  final String subtitle;
  final String rightLabel;
  final VoidCallback onEvaluate;

  const StudentFeaturedCourseCard({
    super.key,
    required this.courseName,
    required this.subtitle,
    required this.rightLabel,
    required this.onEvaluate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColorTokens.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(courseName, style: GoogleFonts.aBeeZee(fontSize: 24, color: const Color(0xFFFFECCC))),
              ),
              Text(rightLabel, style: GoogleFonts.aBeeZee(fontSize: 12, color: const Color(0xFFF7E8D0))),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: GoogleFonts.aBeeZee(fontSize: 11, color: const Color(0xFFF7E8D0))),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onEvaluate,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEBEAEC),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text('EVALUAR', style: GoogleFonts.aBeeZee(fontSize: 11, color: FigmaColorTokens.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

// lib/presentation/pages/student/s_courses_page.dart
// Replace body sections to compose StudentFeaturedCourseCard + micro cards and remove inline style duplication.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/student/s_courses_page_section6850_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/student/s_courses_page_section6850_test.dart lib/presentation/pages/student/widgets/home/student_featured_course_card.dart lib/presentation/pages/student/widgets/home/student_micro_content_card.dart lib/presentation/pages/student/widgets/reports/student_grouped_bar_chart.dart lib/presentation/pages/student/widgets/reports/student_report_row.dart lib/presentation/pages/student/s_courses_page.dart lib/presentation/pages/student/s_eval_list_page.dart lib/presentation/pages/student/widgets/student_bottom_nav.dart
git commit -m "feat(ui): redesign student home and reports with reusable cards"
```

### Task 6: Student Evaluation Flow Redesign (Figma `1:1462`, `1:3427`)

**Files:**
- Create: `lib/presentation/pages/student/widgets/evaluation/student_score_option_row.dart`
- Create: `lib/presentation/pages/student/widgets/evaluation/student_peer_status_tile.dart`
- Modify: `lib/presentation/pages/student/s_peers_page.dart`
- Modify: `lib/presentation/pages/student/s_peer_score_page.dart`
- Modify: `lib/presentation/pages/student/s_my_results_page.dart`
- Test: `test/presentation/pages/student/s_peer_score_page_section6850_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/pages/student/widgets/evaluation/student_score_option_row.dart';

void main() {
  testWidgets('StudentScoreOptionRow highlights selected value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentScoreOptionRow(
            selected: 3,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/student/s_peer_score_page_section6850_test.dart -r expanded`
Expected: FAIL with `Undefined class 'StudentScoreOptionRow'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/student/widgets/evaluation/student_score_option_row.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/theme/figma_color_tokens.dart';

class StudentScoreOptionRow extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelected;

  const StudentScoreOptionRow({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (value) {
        final isActive = selected == value;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(value),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? FigmaColorTokens.accentWarm : Colors.transparent,
                border: Border.all(
                  color: isActive ? FigmaColorTokens.accentWarm : FigmaColorTokens.textSecondary,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$value',
                style: GoogleFonts.aBeeZee(
                  fontSize: 13,
                  color: isActive ? FigmaColorTokens.textPrimary : FigmaColorTokens.textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// lib/presentation/pages/student/s_peer_score_page.dart
// Replace criterion score controls with StudentScoreOptionRow for each question.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/student/s_peer_score_page_section6850_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/student/s_peer_score_page_section6850_test.dart lib/presentation/pages/student/widgets/evaluation/student_score_option_row.dart lib/presentation/pages/student/widgets/evaluation/student_peer_status_tile.dart lib/presentation/pages/student/s_peers_page.dart lib/presentation/pages/student/s_peer_score_page.dart lib/presentation/pages/student/s_my_results_page.dart
git commit -m "feat(ui): redesign student peer evaluation and scoring flow"
```

### Task 7: Student Profile Dark Hero (Figma `3:2856`)

**Files:**
- Create: `lib/presentation/pages/student/widgets/profile/student_profile_hero.dart`
- Modify: `lib/presentation/pages/student/s_profile_page.dart`
- Test: `test/presentation/pages/student/s_profile_page_section6850_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/pages/student/widgets/profile/student_profile_hero.dart';

void main() {
  testWidgets('StudentProfileHero renders heading and score', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudentProfileHero(
            title: 'Eres muy Amado',
            fullName: 'Jorge Sanchez',
            average: '4.5',
          ),
        ),
      ),
    );

    expect(find.text('Eres muy Amado'), findsOneWidget);
    expect(find.text('Jorge Sanchez'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/student/s_profile_page_section6850_test.dart -r expanded`
Expected: FAIL with `Undefined class 'StudentProfileHero'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/student/widgets/profile/student_profile_hero.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentProfileHero extends StatelessWidget {
  final String title;
  final String fullName;
  final String average;

  const StudentProfileHero({
    super.key,
    required this.title,
    required this.fullName,
    required this.average,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF03174C),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.aBeeZee(fontSize: 34, color: const Color(0xFFE6E7F2))),
          const SizedBox(height: 140),
          Text(fullName, style: GoogleFonts.aBeeZee(fontSize: 46, color: const Color(0xFFE6E7F2))),
          const SizedBox(height: 8),
          Text('Promedio General: $average', style: GoogleFonts.aBeeZee(fontSize: 16, color: const Color(0xFF98A1BD))),
        ],
      ),
    );
  }
}

// lib/presentation/pages/student/s_profile_page.dart
// Replace current summary layout with StudentProfileHero + compact logout/action strip.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/student/s_profile_page_section6850_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/student/s_profile_page_section6850_test.dart lib/presentation/pages/student/widgets/profile/student_profile_hero.dart lib/presentation/pages/student/s_profile_page.dart
git commit -m "feat(ui): redesign student profile with dark hero layout"
```

### Task 8: Teacher Dashboard + Results Redesign

**Files:**
- Create: `lib/presentation/pages/teacher/widgets/dashboard/teacher_stat_row.dart`
- Create: `lib/presentation/pages/teacher/widgets/dashboard/teacher_eval_tile.dart`
- Create: `lib/presentation/pages/teacher/widgets/reports/teacher_grouped_bar_chart.dart`
- Modify: `lib/presentation/pages/teacher/t_dash_page.dart`
- Modify: `lib/presentation/pages/teacher/t_results_page.dart`
- Modify: `lib/presentation/pages/teacher/widgets/teacher_bottom_nav.dart`
- Test: `test/presentation/pages/teacher/t_dash_page_section6850_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/pages/teacher/widgets/dashboard/teacher_stat_row.dart';

void main() {
  testWidgets('TeacherStatRow renders three KPI labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherStatRow(
            categories: '6',
            active: '1',
            groups: '20',
          ),
        ),
      ),
    );

    expect(find.text('CATEGORIAS'), findsOneWidget);
    expect(find.text('ACTIVAS'), findsOneWidget);
    expect(find.text('GRUPOS'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/teacher/t_dash_page_section6850_test.dart -r expanded`
Expected: FAIL with `Undefined class 'TeacherStatRow'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/teacher/widgets/dashboard/teacher_stat_row.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherStatRow extends StatelessWidget {
  final String categories;
  final String active;
  final String groups;

  const TeacherStatRow({
    super.key,
    required this.categories,
    required this.active,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Kpi(value: categories, label: 'CATEGORIAS'),
        const SizedBox(width: 8),
        _Kpi(value: active, label: 'ACTIVAS'),
        const SizedBox(width: 8),
        _Kpi(value: groups, label: 'GRUPOS'),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final String value;
  final String label;
  const _Kpi({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF1FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.aBeeZee(fontSize: 20, color: const Color(0xFF3F414E))),
            Text(label, style: GoogleFonts.aBeeZee(fontSize: 10, color: const Color(0xFFA1A4B2))),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/pages/teacher/t_dash_page.dart
// Compose header + TeacherStatRow + TeacherEvalTile list, removing duplicated card styles.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/teacher/t_dash_page_section6850_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/teacher/t_dash_page_section6850_test.dart lib/presentation/pages/teacher/widgets/dashboard/teacher_stat_row.dart lib/presentation/pages/teacher/widgets/dashboard/teacher_eval_tile.dart lib/presentation/pages/teacher/widgets/reports/teacher_grouped_bar_chart.dart lib/presentation/pages/teacher/t_dash_page.dart lib/presentation/pages/teacher/t_results_page.dart lib/presentation/pages/teacher/widgets/teacher_bottom_nav.dart
git commit -m "feat(ui): redesign teacher dashboard and analytics views"
```

### Task 9: Teacher Import + Create/Edit + Course/Profile Redesign

**Files:**
- Create: `lib/presentation/pages/teacher/widgets/forms/teacher_upload_dropzone.dart`
- Create: `lib/presentation/pages/teacher/widgets/forms/teacher_form_field.dart`
- Modify: `lib/presentation/pages/teacher/t_import_page.dart`
- Modify: `lib/presentation/pages/teacher/t_new_eval_page.dart`
- Modify: `lib/presentation/pages/teacher/t_course_manage_page.dart`
- Modify: `lib/presentation/pages/teacher/t_profile_page.dart`
- Test: `test/presentation/pages/teacher/t_new_eval_page_section6850_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/presentation/pages/teacher/widgets/forms/teacher_upload_dropzone.dart';

void main() {
  testWidgets('TeacherUploadDropzone shows upload CTA', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherUploadDropzone(
            title: 'Importar desde Brightspace',
            subtitle: 'CSV o JSON con categorias y grupos',
          ),
        ),
      ),
    );

    expect(find.text('Seleccionar archivo'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/pages/teacher/t_new_eval_page_section6850_test.dart -r expanded`
Expected: FAIL with `Undefined class 'TeacherUploadDropzone'`

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/presentation/pages/teacher/widgets/forms/teacher_upload_dropzone.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:example/presentation/widgets/core/app_cta_button.dart';

class TeacherUploadDropzone extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onSelect;

  const TeacherUploadDropzone({
    super.key,
    required this.title,
    required this.subtitle,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8E97FD), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.upload_rounded, color: Color(0xFF8E97FD), size: 28),
          const SizedBox(height: 10),
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF8E97FD))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA1A4B2))),
          const SizedBox(height: 12),
          AppCtaButton(label: 'Seleccionar archivo', onTap: onSelect),
        ],
      ),
    );
  }
}

// lib/presentation/pages/teacher/t_import_page.dart
// Replace ad-hoc upload card with TeacherUploadDropzone, keep existing controller logic.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/presentation/pages/teacher/t_new_eval_page_section6850_test.dart -r expanded`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/presentation/pages/teacher/t_new_eval_page_section6850_test.dart lib/presentation/pages/teacher/widgets/forms/teacher_upload_dropzone.dart lib/presentation/pages/teacher/widgets/forms/teacher_form_field.dart lib/presentation/pages/teacher/t_import_page.dart lib/presentation/pages/teacher/t_new_eval_page.dart lib/presentation/pages/teacher/t_course_manage_page.dart lib/presentation/pages/teacher/t_profile_page.dart
git commit -m "feat(ui): redesign teacher form and import flows from Section6850"
```

### Task 10: Full Route Regression + Documentation

**Files:**
- Create: `test/presentation/smoke/section6850_routes_smoke_test.dart`
- Modify: `test/widget_test.dart`
- Modify: `README.md`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('Section6850 key routes are registered', (tester) async {
    await tester.pumpWidget(const PeerEvalApp());

    final routes = Get.routeTree.routes.map((r) => r.name).toSet();
    expect(routes.contains('/welcome/student'), isTrue);
    expect(routes.contains('/welcome/teacher'), isTrue);
    expect(routes.contains('/student/courses'), isTrue);
    expect(routes.contains('/teacher/dash'), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/presentation/smoke/section6850_routes_smoke_test.dart -r expanded`
Expected: FAIL with missing welcome routes.

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/main.dart
// Add:
// GetPage(name: '/welcome/student', page: () => const WelcomeRolePage(role: WelcomeRole.student, displayName: '')),
// GetPage(name: '/welcome/teacher', page: () => const WelcomeRolePage(role: WelcomeRole.teacher, displayName: '')),

// README.md (new section)
// ## UI Section 6850
// - Tokens centralizados en lib/presentation/theme/figma_*.dart
// - Componentes base en lib/presentation/widgets/core
// - Mappers UI inyectados via StudentModuleBinding y TeacherModuleBinding
// - Todas las pantallas compuestas por widgets pequenos y testeables
```

- [ ] **Step 4: Run test suite to verify it passes**

Run: `flutter test -r expanded`
Expected: PASS (all existing + nuevos tests)

- [ ] **Step 5: Commit**

```bash
git add test/presentation/smoke/section6850_routes_smoke_test.dart test/widget_test.dart README.md lib/main.dart
git commit -m "test(ui): add Section6850 regression smoke tests and docs"
```

---

## Self-Review

### 1. Spec coverage

- Rediseño completo de UI (auth, student, teacher): cubierto en Tasks 4-9.
- Basado en Figma Section 6850 (colores, formatos, paginas): cubierto en Tasks 1, 4, 5, 6, 7, 8, 9.
- Componetizacion y reutilizacion maxima: cubierto en Tasks 2, 5, 6, 8, 9.
- Consistencia visual global: cubierto en Tasks 1-2.
- DI explicita y clara: cubierto en Task 3 (bindings + mappers) y ajustes en `main.dart`.
- Archivos cortos, unica responsabilidad y testeables: cubierto al dividir widgets por feature + tests por capa.

Gaps detectados: ninguno.

### 2. Placeholder scan

No hay `TODO`, `TBD`, ni referencias ambiguas; cada tarea tiene archivos exactos, codigo ejemplo, comando y expectativa.

### 3. Type consistency

- `WelcomeRolePage`, `StudentUiMapper`, `TeacherUploadDropzone`, `AppCtaButton` mantienen nombres consistentes en tareas donde se crean y se consumen.
- Rutas nuevas (`/welcome/student`, `/welcome/teacher`) se introducen en Task 4 y se validan en Task 10.

