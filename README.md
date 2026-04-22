# EvalUn — Documentación del Proyecto

**EvalUn** es una aplicación móvil desarrollada en **Flutter** que habilita la **coevaluación estructurada entre pares** en entornos académicos colaborativos. Permite que los estudiantes valoren el desempeño de sus compañeros de grupo con criterios explícitos y una escala común, mientras los docentes **organizan cursos y categorías**, **importan Categorías desde CSV (Brightspace)** y **supervisan resultados y métricas** con vistas diferenciadas por rol.

### Equipo de desarrollo

Cristian Gonzalez · Sandro Torres · Jorge Sanchez · Flavio Arregoces

---
### Lista de Reproduccion de demos de la aplicación

1. https://youtube.com/playlist?list=PLMmWS-wQZz0tdo-ewFpPAVKbTFryHhaI3&si=bM17mEYonFhqa3eG

## Tabla de contenidos

1. [Descripción de la aplicación](#1-descripción-de-la-aplicación)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Arquitectura](#3-arquitectura)
4. [Backend, sesión y caché](#4-backend-sesión-y-caché)
5. [Estructura del proyecto](#5-estructura-del-proyecto)
6. [Rutas y navegación](#6-rutas-y-navegación)
7. [Flujo del profesor](#7-flujo-del-profesor)
8. [Flujo del estudiante](#8-flujo-del-estudiante)
9. [Estados de evaluación por estudiante](#9-estados-de-evaluación-por-estudiante)
10. [Funcionalidades](#10-funcionalidades)
11. [Datos y documentación del modelo](#11-datos-y-documentación-del-modelo)
12. [Autenticación y sesión](#12-autenticación-y-sesión)
13. [Posición frente a otras herramientas](#13-posición-frente-a-otras-herramientas)
14. [KPIs orientativos](#14-kpis-orientativos)
15. [Limitaciones, roadmap e integraciones](#15-limitaciones-roadmap-e-integraciones)
16. [Estrategia de pruebas](#16-estrategia-de-pruebas)

---

## 1. Descripción de la aplicación

Nombre del producto: **EvalUn**.

### Propósito del proyecto

En muchos cursos con trabajo colaborativo, la **nota grupal** no refleja por sí sola el aporte individual. EvalUn busca **formalizar la coevaluación entre pares** dentro de una app móvil: los estudiantes participan activamente en la valoración del desempeño de sus compañeros según **criterios compartidos y ventanas de tiempo**, y los docentes obtienen **lecturas agregadas** que apoyan la retroalimentación y la gestión del curso. La intención es mejorar **equidad percibida**, **transparencia del proceso** y **continuidad** respecto a instrumentos ad hoc (formularios genéricos o hojas de cálculo).

### Objetivos

**Objetivo general**

Desarrollar una aplicación móvil que permita la **coevaluación estructurada** entre estudiantes en actividades grupales, con **métricas y vistas claras** para docentes y estudiantes, apoyada en un **backend institucional (Roble)** y en flujos de importación compatibles con **Brightspace** vía CSV.

**Objetivos específicos**

- Permitir la **gestión de cursos y categorías de grupos** desde el rol docente, incluyendo creación de cursos y administración de la estructura usada en evaluaciones.
- Implementar **importación de grupos y miembros** a partir de archivos CSV alineados con exportaciones típicas de Brightspace (grupo, usuario, nombre, correo, etc.).
- Proveer **evaluaciones con ventana temporal** (`closes_at`), **visibilidad configurable** de resultados (pública/privada en la medida definida por negocio) y **cuatro criterios fijos** en escala **2–5**.
- Soportar **evaluación entre compañeros del mismo grupo** (lista de pares sin autoevaluación en el flujo de scoring) y **persistencia idempotente** de respuestas para evitar duplicados al reenviar.
- Calcular y mostrar **promedios y desgloses por criterio**, **resultados por grupo** y **vistas de métricas agregadas** para el docente (`/teacher/results`, `/teacher/data-insights`).
- Ofrecer **caché de lectura** con invalidación por refresco (**pull-to-refresh**) para reducir llamadas repetidas al API manteniendo datos coherentes tras cambios.

### Funcionalidades principales

- Autenticación y registro (estudiante y profesor) contra **Roble**, con sesión local en **SharedPreferences**.
- Gestión docente de **cursos** y **importación CSV** de categorías/grupos/miembros.
- **CRUD de evaluaciones** (crear, renombrar, eliminar) con reglas en repositorio.
- Flujo estudiantil: **lista de evaluaciones**, **estados por persona** (pendiente/completada/cerrada), **evaluación por criterios**, **envío completo**.
- **Control de ventana temporal** para evaluaciones activas vs cerradas.
- **Visualización de resultados** para estudiante y profesor según permisos y visibilidad.
- **Indicadores y vistas analíticas** para docentes (resultados detallados + insights).
- **Caché** de listados frecuentes y refresco manual en pantallas clave.

### Roles del sistema

**Profesor**

- Crear y gestionar **cursos** y la jerarquía usada en evaluaciones (**categorías / grupos**).
- **Importar** membresías desde CSV exportado desde Brightspace (formato compatible documentado en el código de importación).
- **Crear, renombrar y eliminar evaluaciones** asociadas a categorías del curso.
- Configurar **duración** (ventana de evaluación) y **visibilidad** de resultados según las opciones del modelo.
- Consultar **resultados por grupo y criterio**, rankings y **métricas agregadas** en las pantallas docentes.

**Estudiante**

- Registrarse e iniciar sesión con el mismo flujo unificado de login que el profesor (resolución de rol tras autenticar).
- Ver **evaluaciones asignadas** a su grupo y el **estado individual** de cada una.
- **Evaluar a sus compañeros** (cuatro criterios, escala 2–5), con progreso explícito hasta completar todos los pares.
- **Consultar resultados personales** cuando la evaluación y la política de visibilidad lo permitan.

### Tecnologías de la solución

Resumen ejecutivo: **Flutter**, **GetX**, **Roble** (API de datos y autenticación), **Brightspace** como fuente habitual de datos vía **CSV**, **SharedPreferences** para sesión y caché de lectura. El detalle de versiones y paquetes está en [2 Stack tecnológico](#2-stack-tecnológico).

### Alcance

EvalUn cubre el **ciclo principal de una coevaluación por curso/grupo**: preparación del espacio académico (curso + importación), definición de evaluaciones con ventana de tiempo, recolección estructurada de puntajes entre pares, consolidación para **métricas individuales y de grupo**, y visualización diferenciada por rol. La solución está pensada para **contextos universitarios** y para convivir con el ecosistema **Uninorte / OpenLab** mediante Roble.

No sustituye por sí sola un LMS completo: la integración profunda con Brightspace más allá del CSV y los flujos automáticos (notificaciones, SSO pleno) están descritos como evolución en [15](#15-limitaciones-roadmap-e-integraciones).

### Principios de diseño

- **Claridad:** cada rol entiende qué hacer en cada pantalla.
- **Rapidez:** flujos cortos y acciones directas.
- **Trazabilidad:** respuestas guardadas de forma consistente y UX que preserva el **anonimato entre pares** frente al evaluado.

---

## 2. Stack tecnológico

| Área | Tecnología | Rol |
|------|------------|-----|
| Framework | Flutter (Dart ^3.9.2) | iOS / Android |
| Estado, rutas, DI | GetX ^4.7.3 | Observables, navegación, bindings |
| Backend | **Roble API** (`roble_api_database` ^1.0.3) + HTTP puntual (`http` ^1.6.0) | Persistencia y auth en la nube (OpenLab — Uninorte) |
| Config | `flutter_dotenv`, `.env` | URL y parámetros de entorno |
| Sesión local | `shared_preferences` ^2.5.3 | Tokens y snapshot de sesión por rol |
| Caché de lectura | `SharedPreferencesCacheService` → `ICacheService` | Lista de evaluaciones, cursos, categorías y resultados (refresh en UI) |
| Otros | `connectivity_plus`, `file_picker`, `uuid`, Google Fonts | Conectividad, CSV, IDs, tipografía |

---

## 3. Arquitectura

Se aplica **Clean Architecture pragmatica**: **Dominio** (modelos + contratos), **Datos** (repositorios + `DatabaseService` como fachada Roble), **Presentación** (GetX).

- **Casos de uso:** existen para el dominio docente (`TeacherCreateEvaluationUseCase`, `TeacherImportCsvUseCase`). El resto de la lógica de aplicación vive en controladores donde aporta menos fricción.
- **Controladores:** `StudentController` para el rol estudiante; para docentes hay varios (`TeacherSessionController`, `TeacherCourseImportController`, `TeacherEvaluationController`, `TeacherResultsController`, `TeacherInsightsController`, etc.) agrupados con `TeacherModuleBinding`.

```
lib/
├── domain/           # Modelos + interfaces de repositorios (sin Flutter)
├── data/             # Implementaciones + servicios Roble / sesión / bulk insert
└── presentation/     # Controllers · Pages · Widgets · Themes (estudiante vs profesor)
```

### Inyección de dependencias

Los singletons permanentes se registran en `_AppBindings` (`main.dart`) con `Get.put(..., permanent: true)`, incluyendo `ICacheService`, repositorios y controladores necesarios antes del splash.

---

## 4. Backend, sesión y caché

- **Fuente de verdad:** datos de negocio en **Roble** (API REST), no SQLite local para tablas académicas.
- **Sesión:** login vía Roble; la app guarda tokens y datos mínimos del usuario en **SharedPreferences** con **aislamiento por rol** (guardar sesión estudiante borra la clave de profesor y viceversa).
- **Caché:** lecturas repetidas de listados (evaluaciones del estudiante, listados docentes, resultados por evaluación seleccionada) usan **JSON serializado** en `ICacheService`; las pantallas principales ofrecen **pull-to-refresh** para invalidar y volver a cargar.

---

## 5. Estructura del proyecto

Visión resumida (no lista exhaustiva de archivos):

```
lib/
├── main.dart                      # App, _AppBindings, rutas, splash
├── domain/models/                 # Estudiante, profesor, curso, evaluación, grupos, resultados…
├── domain/repositories/           # Contratos I*Repository
├── domain/use_case/teacher/       # Casos de uso docente
├── domain/services/               # Reglas puras (CSV, evaluación, agregados…)
├── data/repositories/             # Implementaciones Roble
├── data/services/database/        # DatabaseService (auth, CRUD, bulk, sesión)
├── data/services/roble_schema.dart
├── presentation/controllers/
├── presentation/bindings/         # p. ej. teacher_module_binding.dart
├── presentation/pages/
│   ├── auth/
│   ├── student/
│   └── teacher/
└── presentation/theme/            # Paletas estudiante (claro/teal) y profesor (oscuro/oro)
```

---

## 6. Rutas y navegación

### Rutas principales

| Ruta | Descripción |
|------|-------------|
| `/login` | Login unificado (intenta estudiante y luego profesor) |
| `/register` | Registro de estudiante |
| `/student/courses` | Inicio estudiante — evaluaciones activas y hero card |
| `/student/eval-list` | Historial de evaluaciones |
| `/student/peers` | Compañeros a evaluar |
| `/student/peer-score` | Puntuación por criterios |
| `/student/results` | Resultados personales |
| `/student/profile` | Perfil |
| `/teacher/dash` | Panel docente — lista de evaluaciones |
| `/teacher/import` | Importación CSV / gestión de categorías |
| `/teacher/new-eval` | Nueva evaluación |
| `/teacher/results` | Resultados por grupo y criterio |
| `/teacher/data-insights` | Métricas / vistas agregadas |
| `/teacher/courses` | Gestión de cursos |
| `/teacher/profile` | Perfil docente |

Las rutas bajo `/teacher/*` (salvo las que compartís binding global) usan **`TeacherModuleBinding`** para inyectar controladores docentes.

### Navegación estudiante (resumen)

```
/login → /student/courses (bottom nav: Inicio, Historial, Resultados, Perfil)
         ├→ /student/peers → /student/peer-score
         └→ /student/results
```

---

## 7. Flujo del profesor

- **Acceso:** registro/login contra Roble; sesión restaurada en el splash si hay preferencias válidas.
- **Panel (`/teacher/dash`):** lista de evaluaciones con acciones de renombrar/eliminar; acceso a crear evaluación; pull-to-refresh opcional para recargar listas cacheadas.
- **Importación (`/teacher/import`):** CSV estilo Brightspace (columnas de grupo, usuario, nombre, correo, etc.); creación de categorías y grupos asociados al curso; importación masiva optimizada en pocos viajes a API.
- **Nueva evaluación:** nombre, categoría, duración, visibilidad; criterios fijos en escala 2–5.
- **Resultados:** agregados por grupo y criterio; detalle por estudiante según la vista implementada.
- **Métricas (`/teacher/data-insights`):** lecturas agregadas para seguimiento docente (según la versión actual del módulo).
- **Cursos (`/teacher/courses`):** administración de cursos en la medida expuesta por la app.

---

## 8. Flujo del estudiante

- **Login unificado** en la misma pantalla que el profesor; el controlador resuelve el rol tras autenticar.
- **Inicio:** hero card para la evaluación pendiente más reciente (si aplica), lista de evaluaciones activas con **estado individual** (ver 9), pull-to-refresh.
- **Historial:** todas las evaluaciones con badges de estado.
- **Evaluación:** lista de compañeros → pantalla de puntuación por cuatro criterios → envío idempotente de respuestas.
- **Resultados:** promedio y desglose cuando la evaluación y la visibilidad lo permiten.

---

## 9. Estados de evaluación por estudiante

El estado por evaluación se calcula en `StudentController` (`evalStatuses`).

```dart
enum EvalStudentStatus {
  activePending,      // Ventana abierta y aún faltan compañeros por evaluar
  activeCompleted,    // Ventana abierta y ya evaluó a todos
  closedNotDone,      // Cerrada sin completar
  closedCompleted,    // Cerrada habiendo completado a tiempo
}
```

Lógica resumida: si la evaluación está dentro de `closesAt` y el estudiante completó todos los pares → `activeCompleted`; si no → `activePending`. Si ya cerró, se distingue entre completada o no.

---

## 10. Funcionalidades

### Profesor

- [x] Autenticación Roble y sesión local
- [x] Importación CSV (Brightspace) y gestión de categorías/grupos/cursos
- [x] CRUD de evaluaciones (crear, renombrar, eliminar) con reglas de negocio en repositorio
- [x] Resultados por grupo/criterio y vistas de métricas
- [x] Caché de lecturas con refresco explícito en dashboard e importación

### Estudiante

- [x] Registro/login y sesión
- [x] Dashboard, historial y estados por evaluación
- [x] Evaluación entre pares (cuatro criterios, escala 2–5) y envío completo
- [x] Resultados personales según reglas de visibilidad
- [x] Pull-to-refresh en listas principales

### Próximas mejoras (alto nivel)

Ver 15: SSO institucional más estrecho, API Brightspace directa, automatización (p. ej. n8n) y notificaciones push donde aplique.

---

## 11. Datos y documentación del modelo

El detalle de tablas y relaciones objetivo está en **[docs/DATABASE.md](docs/DATABASE.md)** (alineado con **[docs/db.dbml](docs/db.dbml)**). La app habla con Roble; no usar este README como esquema SQL literal de runtime — la fuente de verdad del contrato es la API y el DBML del repositorio.

---

## 12. Autenticación y sesión

1. **Login:** credenciales contra Roble (`robleLogin`); se almacenan tokens en el cliente y se derivan claims JWT (`sub`, rol, etc.).
2. **Registro:** alta vía API y sincronización de fila de usuario cuando hace falta para reglas de la app.
3. **Splash:** comprueba sesión de estudiante y de profesor en paralelo y navega al home correspondiente o al login.
4. **Logout:** invalida tokens cuando aplica, limpia preferencias del rol y estado en controladores (incluida invalidación de caché donde está implementada).

---

## 13. Posición frente a otras herramientas

| Plataforma | Evaluación entre pares | Integración LMS | App móvil nativa | Automatización |
|------------|------------------------|-----------------|------------------|----------------|
| **EvalUn** | Estructurada por criterios | CSV Brightspace hoy; API como mejora | Flutter | Ampliable (workflows externos en roadmap) |
| Buddycheck | Sí | Parcial | Web | Manual |
| CATME | Sí | No | Web | Manual |
| Peergrade | Sí | Limitada | Web | Manual |

**Diferencias que cuidamos:** experiencia móvil, estado fino por estudiante (no solo “la evaluación cerró”), anonimato entre pares en la UX, y backend gestionado (**Roble**) sin montar servidor propio para la asignatura.

---

## 14. KPIs orientativos

| KPI | Meta orientativa v1 |
|-----|---------------------|
| Participación (completan en ventana) | > 85% |
| Tiempo medio de finalización | < 8 min |
| Adopción docente (≥1 eval/semestre) | > 70% |
| Satisfacción interna (NPS) | > 40 |

---

## 15. Limitaciones, roadmap e integraciones

### Limitaciones actuales (realistas)

- Dependencia de conectividad para operaciones contra Roble; la app gestiona estado offline limitado vía caché de lectura, no un modo “sin red” completo de escritura.
- Sin notificaciones push propias hasta integrar canal (p. ej. FCM + orquestación).
- Importación masiva principalmente por **CSV**; API Brightspace en roadmap.
- Criterios y escala fijos en la versión descrita (cuatro criterios, escala 2–5).

### Roadmap y piezas externas (consolidado)

| Tema | Notas |
|------|--------|
| **Brightspace** | Hoy CSV con columnas estándar; API directa como evolución. |
| **SSO / cuenta institucional Roble** | Mejora de login cuando el proveedor lo exponga de forma estable a la app. |
| **n8n u orquestador** | Recordatorios, sincronizaciones programadas y piezas administrativas — **planificado**, no parte del núcleo actual de la app. |
| **Panel tiempo real / alertas académicas** | Línea de producto futura. |
| **Multi-LMS** | Canvas/Moodle etc. — visión a largo plazo. |

---

## 16. Estrategia de pruebas

- **Unitarias y de repositorio:** `flutter test` sobre `test/` — modelos, servicios de dominio, repositorios con **fakes** de `DatabaseService` (sin framework de mocks obligatorio en esa capa).
- **Integración de UI / controladores:** suites bajo **`integration_test/`** con `integration_test` + **`mockito`** (mocks generados con `build_runner` desde `integration_test/helpers/mocks.dart`). Permiten ejecutar en **Chrome** con **chromedriver** para acercarse a entorno web real.
- **Helpers compartidos:** `test/helpers/` (`FakeCacheService`, fakes de repositorio, spies de controladores, harness GetX) según el tipo de prueba.

### Comandos útiles

```bash
# Unitarias y tests bajo test/
flutter test

# Integración (ejemplo: descubrir todos los archivos bajo integration_test/)
flutter test integration_test/

# Widget/integration en Chrome (requiere chromedriver acorde a la versión del Chrome usado por Flutter)
flutter drive --driver=test/test_driver/integration_test.dart --target=integration_test/<ruta>_test.dart -d chrome
```

---

*EvalUn reúne arquitectura mantenible, identidad visual, motor de evaluación y visión de producto en un solo repositorio.*
