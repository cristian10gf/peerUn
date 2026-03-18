# EvalUn / Evalia — Documentación del Proyecto

> **Equipo:** Cristian · Sandro · Jorge · Flavio
>
> **Figma:** https://www.figma.com/design/DDNofweJTAejsv44DZ1akb/Untitled?node-id=1-801&t=LxzPnaJQcuQtXxtO-1
>
> **Proyecto:** Plataforma móvil de evaluación entre compañeros para trabajo colaborativo universitario
> **Fecha inicial:** 25 de febrero de 2026
> **Tecnologías:** Flutter · GetX · Clean Architecture · SQLite (sqflite) · Brightspace (CSV)

---

## Tabla de Contenidos

1. [Descripción](#1-descripción)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Arquitectura](#3-arquitectura)
4. [Estructura del proyecto](#4-estructura-del-proyecto)
5. [Rutas y navegación](#5-rutas-y-navegación)
6. [Flujo del Profesor](#6-flujo-del-profesor)
7. [Flujo del Estudiante](#7-flujo-del-estudiante)
8. [Estados de evaluación por estudiante](#8-estados-de-evaluación-por-estudiante)
9. [Funcionalidades implementadas](#9-funcionalidades-implementadas)
10. [Modelo de datos real](#10-modelo-de-datos-real)
11. [Autenticación y sesión](#11-autenticación-y-sesión)
12. [Análisis de competencia](#12-análisis-de-competencia)
13. [Integración con n8n y Brightspace](#13-integración-con-n8n-y-brightspace)
14. [KPIs y métricas de éxito](#14-kpis-y-métricas-de-éxito)
15. [Limitaciones y evolución](#15-limitaciones-y-evolución)

---

## 1. Descripción

**EvalUn** (nombre de código: **Evalia**) es una app móvil Flutter para evaluación entre compañeros en cursos universitarios con trabajo colaborativo. Define dos actores con interfaces completamente separadas que comparten la base de datos local:

- **Profesor:** importa grupos desde CSV/Brightspace, crea y gestiona evaluaciones (renombrar, eliminar), consulta resultados por grupo/criterio.
- **Estudiante:** ve sus evaluaciones activas, evalúa a cada compañero de grupo de forma anónima por 4 criterios, consulta sus resultados.

### Principios de diseño

- **Claridad:** cada actor entiende qué hacer y por qué en cada pantalla.
- **Rapidez:** flujos minimalistas con acciones directas.
- **Responsabilidad:** trazabilidad completa de respuestas sin exponer al evaluador.

---

## 2. Stack tecnológico

| Capa | Tecnología | Versión | Rol |
|---|---|---|---|
| Framework | Flutter | 3.9.2+ | App iOS/Android |
| Lenguaje | Dart | 3.9.2+ | — |
| Estado / Routing / DI | GetX | 4.7.3 | Reactivo, navegación, bindings |
| Base de datos local | sqflite | 2.4.2 | SQLite embebido |
| Tipografía | Google Fonts | 8.0.2 | Sora + DM Mono |
| Criptografía | crypto | 3.0.3 | Hashing de contraseñas |
| Importación de archivos | file_picker | 8.1.2 | CSV desde almacenamiento |
| Análisis estático | flutter_lints | 5.0.0 | Calidad de código |

---

## 3. Arquitectura

Se aplica **Clean Architecture pragmática** con tres capas. No se implementan Use Cases separados; la lógica de aplicación vive directamente en los Controllers (patrón MVVM), reduciendo boilerplate sin sacrificar separación de responsabilidades.

```
lib/
├── domain/          # Modelos + interfaces de repositorios (sin dependencias externas)
├── data/            # Implementaciones de repositorios + DatabaseService (SQLite)
└── presentation/    # Controllers (GetX) · Pages · Widgets · Theme
```

### Inyección de dependencias

Todo se registra en `_AppBindings` dentro de `main.dart` con `Get.put(..., permanent: true)`. El árbol de dependencias es:

```
DatabaseService
  ├── AuthRepositoryImpl          → IAuthRepository
  ├── TeacherAuthRepositoryImpl   → ITeacherAuthRepository
  ├── GroupRepositoryImpl         → IGroupRepository
  └── EvaluationRepositoryImpl    → IEvaluationRepository

StudentController(IAuthRepository, IEvaluationRepository)
TeacherController(ITeacherAuthRepository, IGroupRepository, IEvaluationRepository)

UnifiedAuthRepositoryImpl(IAuthRepository, ITeacherAuthRepository) → IUnifiedAuthRepository
LoginController(IUnifiedAuthRepository, StudentController, TeacherController)
```

---

## 4. Estructura del proyecto

```
lib/
├── main.dart                                    # Entry point, bindings, rutas GetX
│
├── domain/
│   ├── models/
│   │   ├── student.dart                         # Student, initials getter
│   │   ├── teacher.dart                         # Teacher
│   │   ├── course.dart                          # Course (categoryName, groupName, memberCount)
│   │   ├── evaluation.dart                      # Evaluation, isActive getter
│   │   ├── peer_evaluation.dart                 # Peer, EvalCriterion, CriterionResult
│   │   ├── auth_login_result.dart
│   │   └── teacher_data.dart                    # TeacherStats, GroupResult, StudentResult
│   └── repositories/
│       ├── i_auth_repository.dart
│       ├── i_teacher_auth_repository.dart
│       ├── i_group_repository.dart
│       ├── i_evaluation_repository.dart
│       └── i_unified_auth_repository.dart
│
├── data/
│   ├── repositories/
│   │   ├── auth_repository_impl.dart
│   │   ├── teacher_auth_repository_impl.dart
│   │   ├── group_repository_impl.dart
│   │   ├── evaluation_repository_impl.dart      # Incluye hasCompletedAllPeers
│   │   └── unified_auth_repository_impl.dart
│   └── services/
│       └── database_service.dart                # SQLite v5, onCreate/onUpgrade
│
└── presentation/
    ├── controllers/
    │   ├── login_controller.dart
    │   ├── student_controller.dart              # EvalStudentStatus enum + evalStatuses
    │   └── teacher_controller.dart
    ├── pages/
    │   ├── auth/
    │   │   ├── login_page.dart
    │   │   └── register_page.dart
    │   ├── student/
    │   │   ├── s_courses_page.dart              # Dashboard: hero card + lista activas
    │   │   ├── s_eval_list_page.dart            # Historial de todas las evaluaciones
    │   │   ├── s_peers_page.dart                # Lista de compañeros a evaluar
    │   │   ├── s_peer_score_page.dart           # Pantalla de scoring por criterio
    │   │   └── s_my_results_page.dart           # Resultados personales
    │   └── teacher/
    │       ├── t_dash_page.dart                 # Dashboard con lista de evaluaciones
    │       ├── t_import_page.dart               # Importar grupos desde CSV
    │       ├── t_new_eval_page.dart             # Crear evaluación
    │       ├── t_results_page.dart              # Analítica por grupo/criterio
    │       └── t_profile_page.dart              # Perfil y logout
    └── theme/
        ├── app_colors.dart                      # Paleta estudiante (SK — Student Kit)
        └── teacher_colors.dart                  # Paleta profesor (TK — Teacher Kit)
```

---

## 5. Rutas y navegación

### Rutas registradas en `main.dart`

| Ruta | Widget | Descripción |
|---|---|---|
| `/login` | `LoginPage` | Login unificado por rol |
| `/register` | `RegisterPage` | Registro de estudiante |
| `/student/courses` | `SCoursesPage` | **Dashboard estudiante** — evaluaciones activas + hero card |
| `/student/eval-list` | `SEvalListPage` | Historial de evaluaciones |
| `/student/peers` | `SPeersPage` | Lista de compañeros a evaluar |
| `/student/peer-score` | `SPeerScorePage` | Scoring por criterio de un compañero |
| `/student/results` | `SMyResultsPage` | Resultados personales |
| `/teacher/dash` | `TDashPage` | Dashboard docente con lista de evaluaciones |
| `/teacher/import` | `TImportPage` | Importar grupos CSV |
| `/teacher/new-eval` | `TNewEvalPage` | Crear evaluación |
| `/teacher/results` | `TResultsPage` | Analítica de resultados |
| `/teacher/profile` | `TProfilePage` | Perfil del profesor |

### Flujo de navegación estudiante

```
/login
  └─▶ /student/courses          (home, bottom nav index 0)
        ├─▶ /student/peers       (tap "Evaluar" en hero card o eval card)
        │     └─▶ /student/peer-score  (tap un compañero)
        │           └─▶ /student/peers  (guardar score → Get.offNamed)
        └─▶ /student/results     (tap "Ver resultados")

  bottom nav:
    [0] Inicio    → /student/courses
    [1] Historial → /student/eval-list
    [2] Resultados→ /student/results
    [3] Perfil    → (modal bottom sheet)
```

---

## 6. Flujo del Profesor

### T1 · Login / Registro
- Login con correo + contraseña (hash SHA-256 en local).
- Registro manual con nombre, correo y contraseña.
- Sesión persistida en tabla `teacher_sessions`.

### T2 · Dashboard (`/teacher/dash`)
- Lista de evaluaciones creadas por el profesor autenticado (scoping por `teacher_id`).
- Cada evaluación muestra: nombre, categoría, estado (activa/cerrada), tiempo restante.
- Acciones por evaluación: **Renombrar** (modal inline), **Eliminar** (confirmación).
- FAB para crear nueva evaluación.

### T3 · Importar Grupos (`/teacher/import`)
- Selección de archivo CSV desde el dispositivo.
- Formato esperado: `category_name, group_name, member_name, member_username`.
- Crea registros en `group_categories`, `groups` y `group_members`, asociados al `teacher_id`.
- Confirmación con conteo de grupos y miembros importados.

### T4 · Crear Evaluación (`/teacher/new-eval`)
- Nombre de la evaluación.
- Selección de categoría de grupos (previamente importada por este profesor).
- Duración en horas (define `closes_at = created_at + hours`).
- Visibilidad: **Pública** o **Privada**.
- Criterios fijos: Puntualidad · Aportes · Compromiso · Actitud (escala 2–5).

### T5 · Resultados (`/teacher/results`)
- Promedio general por grupo.
- Desglose por criterio (punct, contrib, commit, attitude).
- Vista por estudiante dentro del grupo.

### T6 · Perfil (`/teacher/profile`)
- Datos del profesor y opción de cierre de sesión.

---

## 7. Flujo del Estudiante

### E1 · Login / Registro
- Login unificado (mismo `LoginPage` para ambos roles).
- `LoginController` prueba primero credenciales de estudiante, luego de profesor.
- Registro de estudiante disponible desde la pantalla de login.

### E2 · Dashboard — Evaluaciones (`/student/courses`)

La pantalla principal del estudiante tiene tres zonas:

**Hero card (evaluación pendiente más reciente)**
- Aparece solo si existe al menos una evaluación con estado `activePending`.
- Muestra: nombre, categoría, tiempo restante, barra de progreso (`doneCount/totalPeers`), botón "Evaluar ahora".
- Fondo en color primario (lila) con punto pulsante blanco.
- Cuando no hay evaluaciones pendientes, la hero card desaparece.

**Sección "EVALUACIONES ACTIVAS"**
- Lista todas las evaluaciones cuyo `closes_at` no ha vencido.
- Cada card muestra el estado del estudiante (ver sección 8) con badge y color correspondiente.
- Botón "Evaluar" solo visible en estado `activePending`.
- Botón "Ver resultados" siempre visible.

**Bottom navigation bar**
- Inicio · Historial · Resultados · Perfil

### E3 · Historial (`/student/eval-list`)
- Lista **todas** las evaluaciones (activas y cerradas) del estudiante.
- Badge de estado por evaluación (ver sección 8).
- Botón "Evaluar" solo si estado `activePending`.
- Botón "Ver resultados" siempre presente.

### E4 · Lista de compañeros (`/student/peers`)
- Muestra el nombre de la evaluación y el grupo del estudiante.
- Barra de progreso: `doneCount/totalPeers`.
- Cards de cada compañero: estado Pendiente / Evaluado (con check).
- Al completar todos, aparece botón "Enviar evaluación completa".
- Back button usa `Get.back()` (compatible desde /courses o /eval-list).

### E5 · Scoring por criterio (`/student/peer-score`)
- Encabezado con nombre e iniciales del compañero.
- 4 tarjetas de criterio: Puntualidad, Aportes, Compromiso, Actitud.
- Cada criterio: botones de selección 2/3/4/5 + etiqueta de nivel.
- Botón "Guardar y continuar" habilitado solo con los 4 criterios seleccionados.
- Al guardar: `ctrl.savePeerScore()` → `Get.offNamed('/student/peers')`.

### E6 · Resultados (`/student/results`)
- Promedio general recibido (grande, en color primario).
- Badge de desempeño: Excelente / Buen / Adecuado / Necesita mejorar.
- Desglose por criterio con barra de progreso.
- Muestra el nombre e indicador de visibilidad de la evaluación activa.

---

## 8. Estados de evaluación por estudiante

El estado de una evaluación para un estudiante específico es calculado en el `StudentController` y almacenado en `evalStatuses: RxMap<int, EvalStudentStatus>`.

### Enum `EvalStudentStatus`

```dart
enum EvalStudentStatus {
  activePending,    // La evaluación está activa Y el estudiante no ha evaluado a todos
  activeCompleted,  // La evaluación está activa Y el estudiante ya evaluó a todos
  closedNotDone,    // El tiempo venció Y el estudiante no completó
  closedCompleted,  // El tiempo venció Y el estudiante completó antes del cierre
}
```

### Lógica de determinación

```
isActive = DateTime.now().isBefore(eval.closesAt)
completed = hasCompletedAllPeers(evalId, email, studentId)

si isActive:
    completed → activeCompleted
    !completed → activePending
si !isActive:
    completed → closedCompleted
    !completed → closedNotDone
```

`hasCompletedAllPeers` consulta la BD: obtiene el grupo del estudiante, cuenta sus peers totales y verifica cuántos tienen respuestas guardadas por ese evaluador. Retorna `true` si `done >= total && total > 0`.

### Representación visual

| Estado | Badge | Color borde | Botón Evaluar | Hero card |
|---|---|---|---|---|
| `activePending` | `ACTIVA` + punto pulsante | lila (`skPrimaryMid`) | ✅ visible | ✅ aparece |
| `activeCompleted` | `ACTIVA · REALIZADA` + ✓ | verde (`critGreen`) | ❌ oculto | ❌ no aparece |
| `closedNotDone` | `FINALIZADA · NO REALIZADA` | rojo suave | ❌ oculto | ❌ no aparece |
| `closedCompleted` | `FINALIZADA` | `skBorder` (neutro) | ❌ oculto | ❌ no aparece |

### Cuándo se recomputa

| Evento | Acción |
|---|---|
| Login exitoso de estudiante | `loadEvalData()` → `_computeStatuses()` para todas las evals |
| `submitEvaluation()` | Recomputa solo la eval recién enviada y actualiza `evalStatuses[eval.id]` |
| Logout | `_resetEvalState()` → `evalStatuses.clear()` |

---

## 9. Funcionalidades implementadas

### Profesor
- [x] Registro e inicio de sesión con persistencia de sesión
- [x] Scoping por `teacher_id` (cada profesor ve solo sus datos)
- [x] Importar grupos desde archivo CSV
- [x] Crear evaluación (nombre, categoría, horas, visibilidad)
- [x] Renombrar evaluación (con validación de nombre duplicado)
- [x] Eliminar evaluación (elimina también sus respuestas)
- [x] Ver resultados por grupo y por criterio
- [x] Perfil con datos y logout

### Estudiante
- [x] Registro e inicio de sesión con persistencia de sesión
- [x] Dashboard con hero card de evaluación pendiente más reciente
- [x] Lista de evaluaciones activas con estado individual
- [x] Historial de todas las evaluaciones con badge de estado
- [x] Evaluar compañeros por 4 criterios (escala 2–5)
- [x] Progreso de evaluación (doneCount/totalPeers)
- [x] Enviar evaluación completa (persiste en `evaluation_responses`)
- [x] Estado automático `activePending → activeCompleted` al enviar
- [x] Estado `closedNotDone` para evaluaciones vencidas no completadas
- [x] Ver resultados personales con promedio y desglose por criterio
- [x] Perfil con logout desde bottom nav

### Pendiente (roadmap)
- [ ] Integración SSO con Roble
- [ ] Sincronización con Brightspace API (hoy solo CSV)
- [ ] Orquestación con n8n (notificaciones, recordatorios)
- [ ] Panel de monitoreo en tiempo real para el profesor
- [ ] Señales de alerta 0/1 separadas del cálculo académico
- [ ] Módulo de recursos de aprendizaje colaborativo

---

## 10. Modelo de datos real

El esquema completo está documentado en [DATABASE.md](DATABASE.md).

### Resumen de tablas

| Tabla | Descripción |
|---|---|
| `students` | Cuentas de estudiantes |
| `sessions` | Sesión activa del estudiante (máx. 1) |
| `teachers` | Cuentas de profesores |
| `teacher_sessions` | Sesión activa del profesor (máx. 1) |
| `group_categories` | Categorías importadas (ej. "Proyecto Final") |
| `groups` | Grupos dentro de una categoría |
| `group_members` | Miembros de cada grupo (con username = email) |
| `evaluations` | Evaluaciones creadas por un profesor |
| `evaluation_responses` | Respuestas individuales por criterio |

### Relaciones clave

```
teachers ──< group_categories ──< groups ──< group_members
teachers ──< evaluations
              evaluations.category_id → group_categories.id
evaluation_responses.eval_id → evaluations.id
evaluation_responses.evaluator_id → students.id
evaluation_responses.evaluated_member_id → group_members.id
```

---

## 11. Autenticación y sesión

### Flujo actual (local, sin SSO)

**Registro de estudiante:**
1. `AuthRepositoryImpl.register(name, email, password)`
2. Verifica duplicado de email en `students`.
3. Guarda contraseña hasheada con SHA-256.
4. Crea registro en `sessions` con `id = 1`.

**Login:**
1. `LoginController.login(email, password)` prueba primero `IAuthRepository` (estudiante), luego `ITeacherAuthRepository` (profesor).
2. Compara hash SHA-256 de la contraseña ingresada.
3. Guarda sesión en la tabla correspondiente.
4. Navega a `/student/courses` o `/teacher/dash`.

**Restauración de sesión (splash):**
- Al iniciar la app, `_SplashPage` llama `student.checkSession()` y `teacher.checkSession()` en paralelo.
- Si existe registro en `sessions`/`teacher_sessions`, restaura la sesión sin login.

**Logout:**
- Elimina el registro de sesión de la BD y limpia el estado del controller.
- Navega a `/login`.

### Integración SSO Roble (planificada)

Ver sección 13. Actualmente no implementada.

---

## 12. Análisis de competencia

| Plataforma | Evaluación entre pares | Integración LMS | App móvil nativa | Automatización |
|---|---|---|---|---|
| **EvalUn** | ✅ Estructurada | ✅ Brightspace (CSV hoy, API planificada) | ✅ Flutter | 🔜 n8n planificado |
| Buddycheck | ✅ Sí | ✅ Parcial | ❌ Web | ❌ Manual |
| CATME | ✅ Sí | ❌ No | ❌ Web | ❌ Manual |
| Peergrade | ✅ Sí | ⚠️ Limitada | ❌ Web | ❌ Manual |
| Canvas Peer Review | ⚠️ Básica | ✅ Canvas | ❌ Web | ⚠️ Parcial |

### Ventajas diferenciales

1. **Móvil first:** diseñada para el contexto real del estudiante universitario.
2. **Estado por estudiante:** cada evaluación tiene un estado individual (pendiente/realizada/no realizada), no solo activa/cerrada a nivel global.
3. **Anonimato garantizado:** el nombre del evaluador no se almacena con sus respuestas individuales visibles.
4. **Importación flexible:** CSV hoy, API Brightspace en roadmap.
5. **Cero backend propio:** SQLite local + n8n para operaciones asíncronas.

---

## 13. Integración con n8n y Brightspace

> Estado: **planificado**, no implementado en la versión actual.

### Brightspace
- Fuente oficial de cursos, grupos y membresías estudiantiles.
- Hoy se importa mediante CSV; la integración API directa es roadmap v2.

### n8n — Workflows planificados

| Workflow | Disparador | Acción |
|---|---|---|
| Sincronización de grupos | Programado (diario) | Actualiza grupos desde Brightspace |
| Activación de evaluación | Evento: profesor crea evaluación | Notifica push a estudiantes del grupo |
| Recordatorio | Cada N horas si sin completar | Push a estudiantes con `activePending` |
| Cierre automático | `closes_at` alcanzado | Marca evaluaciones como cerradas |
| Registro de estudiante | Nuevo miembro en CSV | Crea cuenta y envía correo de activación |
| Registro de profesor | Nuevo registro | Envía correo de confirmación |

---

## 14. KPIs y métricas de éxito

| KPI | Meta v1 |
|---|---|
| Tasa de participación (% que completan dentro de la ventana) | > 85% |
| Tiempo de finalización promedio | < 8 min |
| Adopción docente (al menos 1 eval/semestre) | > 70% |
| NPS interno al final del semestre | > 40 |

---

## 15. Limitaciones y evolución

### Limitaciones actuales

- Persistencia 100% local (SQLite); sin sincronización entre dispositivos.
- Sin notificaciones push (requiere n8n + FCM).
- Importación solo por CSV; sin API Brightspace directa.
- Sin SSO Roble (login manual solamente).
- Los criterios de evaluación son fijos (4 criterios, escala 2–5).

### Roadmap

| Versión | Funcionalidad |
|---|---|
| v1.1 | Integración n8n + notificaciones push |
| v1.1 | Importación directa desde Brightspace API |
| v2.0 | SSO Roble |
| v2.0 | Panel de monitoreo en tiempo real para el profesor |
| v2.0 | Señales de alerta 0/1 separadas del cálculo académico |
| v2.0 | Analítica avanzada: sesgo, outliers, tendencias por semestre |
| v3.0 | Microcontenidos adaptativos por perfil de desempeño |
| v3.0 | Módulo de autoevaluación opcional |
| v3.0 | Dashboard institucional para coordinadores |
| v3.0 | Soporte multi-LMS (Canvas, Moodle) |

---

*Evalia unifica los aportes del equipo: arquitectura limpia (Cristian), identidad visual y nombre (Sandro), motor de evaluación y n8n (Jorge), análisis competitivo (Flavio).*
