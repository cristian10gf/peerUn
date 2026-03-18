# DATABASE.md — Documentación de la Base de Datos

> Base de datos local SQLite gestionada por `sqflite`.
> Archivo: `{getDatabasesPath()}/peereval.db`
> Versión actual: **5**

---

## Tabla de Contenidos

1. [Esquema completo](#1-esquema-completo)
2. [Descripción de cada tabla](#2-descripción-de-cada-tabla)
3. [Diagrama de relaciones](#3-diagrama-de-relaciones)
4. [Historial de versiones (migrations)](#4-historial-de-versiones-migrations)
5. [Repositorios y métodos](#5-repositorios-y-métodos)
6. [Consultas SQL clave](#6-consultas-sql-clave)
7. [Estado de evaluación por estudiante](#7-estado-de-evaluación-por-estudiante)
8. [Flujos de datos completos](#8-flujos-de-datos-completos)

---

## 1. Esquema completo

```sql
-- Autenticación: estudiantes
CREATE TABLE students (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT    NOT NULL,
  email    TEXT    NOT NULL UNIQUE,
  password TEXT    NOT NULL,        -- SHA-256 hex del password
  initials TEXT    NOT NULL         -- calculado al registrar
);

-- Sesión activa del estudiante (máximo 1 fila, id siempre = 1)
CREATE TABLE sessions (
  id         INTEGER PRIMARY KEY,   -- siempre 1
  student_id INTEGER,
  FOREIGN KEY (student_id) REFERENCES students(id)
);

-- Autenticación: profesores
CREATE TABLE teachers (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  name     TEXT    NOT NULL,
  email    TEXT    NOT NULL UNIQUE,
  password TEXT    NOT NULL,        -- SHA-256 hex del password
  initials TEXT    NOT NULL
);

-- Sesión activa del profesor (máximo 1 fila, id siempre = 1)
CREATE TABLE teacher_sessions (
  id         INTEGER PRIMARY KEY,   -- siempre 1
  teacher_id INTEGER,
  FOREIGN KEY (teacher_id) REFERENCES teachers(id)
);

-- Categorías de grupos (ej. "Proyecto Final", "Talleres")
CREATE TABLE group_categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  imported_at INTEGER NOT NULL,     -- UNIX ms (DateTime.millisecondsSinceEpoch)
  teacher_id  INTEGER NOT NULL DEFAULT 0
);

-- Grupos dentro de una categoría (ej. "Grupo A")
CREATE TABLE groups (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL,
  name        TEXT    NOT NULL,
  FOREIGN KEY (category_id) REFERENCES group_categories(id)
);

-- Miembros de cada grupo
CREATE TABLE group_members (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  group_id INTEGER NOT NULL,
  name     TEXT    NOT NULL,    -- nombre completo del estudiante
  username TEXT    NOT NULL,    -- email del estudiante (usado para cruzar con students)
  FOREIGN KEY (group_id) REFERENCES groups(id)
);

-- Evaluaciones creadas por un profesor
CREATE TABLE evaluations (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  category_id INTEGER NOT NULL,   -- qué categoría de grupos abarca
  hours       INTEGER NOT NULL,   -- duración; closes_at = created_at + hours
  visibility  TEXT    NOT NULL,   -- 'public' | 'private'
  created_at  INTEGER NOT NULL,   -- UNIX ms
  closes_at   INTEGER NOT NULL,   -- UNIX ms
  teacher_id  INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (category_id) REFERENCES group_categories(id)
);

-- Respuestas individuales (una fila por evaluador × evaluado × criterio)
CREATE TABLE evaluation_responses (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  eval_id             INTEGER NOT NULL,
  evaluator_id        INTEGER NOT NULL,   -- students.id (no group_members.id)
  evaluated_member_id INTEGER NOT NULL,   -- group_members.id (no students.id)
  criterion_id        TEXT    NOT NULL,   -- 'punct' | 'contrib' | 'commit' | 'attitude'
  score               INTEGER NOT NULL,   -- 2..5
  FOREIGN KEY (eval_id) REFERENCES evaluations(id)
);
```

---

## 2. Descripción de cada tabla

### `students`
Almacena los usuarios con rol estudiante. El campo `password` guarda el hash SHA-256 en hexadecimal (nunca la contraseña en texto plano). `initials` se calcula al registrar (primera letra del primer nombre + primera letra del apellido).

### `sessions`
Tabla de sesión simple de una sola fila. Cuando un estudiante hace login se hace `INSERT OR REPLACE` con `id = 1`. Al hacer logout se elimina esa fila. Al abrir la app, si existe la fila, la sesión se restaura automáticamente.

### `teachers` / `teacher_sessions`
Mismo patrón que `students` / `sessions` pero para el rol profesor.

### `group_categories`
Representa una categoría de grupos importada desde CSV (ej. "Proyecto Final 2026"). Pertenece a un profesor (`teacher_id`). Una evaluación se asocia a una categoría, abarcando automáticamente todos los grupos dentro de ella.

### `groups`
Un grupo específico dentro de una categoría (ej. "Grupo 3"). Cada grupo tiene varios miembros.

### `group_members`
Un miembro dentro de un grupo. El campo `username` es el email del estudiante y se usa para cruzar datos con la tabla `students` (con `LOWER(username) = LOWER(students.email)`). El `id` de esta tabla es lo que se usa como `evaluated_member_id` en las respuestas.

> **Nota importante:** `group_members.id` ≠ `students.id`. Un estudiante puede no tener cuenta aún en `students` pero ya estar en `group_members` (importado via CSV antes de registrarse).

### `evaluations`
Una evaluación creada por un profesor. La ventana de tiempo se calcula al crear: `closes_at = created_at + hours * 3600 * 1000`. El campo `isActive` no se almacena; se deriva en runtime: `DateTime.now().isBefore(closesAt)`.

Los criterios de evaluación son fijos en el código (no en BD):

| criterion_id | Nombre |
|---|---|
| `punct` | Puntualidad |
| `contrib` | Aportes al equipo |
| `commit` | Compromiso |
| `attitude` | Actitud |

### `evaluation_responses`
Cada fila representa la calificación que dio `evaluator_id` (students.id) al miembro `evaluated_member_id` (group_members.id) en el criterio `criterion_id` dentro de la evaluación `eval_id`. Se generan 4 filas por par evaluador→evaluado (una por criterio).

---

## 3. Diagrama de relaciones

```
teachers (id)
    │
    ├──< group_categories (teacher_id)
    │         │
    │         ├──< groups (category_id)
    │         │         │
    │         │         └──< group_members (group_id)
    │         │                   │
    │         │                   └── evaluated_member_id ──┐
    │         │                                              │
    │         └──< evaluations (category_id, teacher_id)    │
    │                   │                                   │
    │                   └──< evaluation_responses ──────────┘
    │                             │
    │                   evaluator_id ──────────────── students (id)
    │
students (id) ──── sessions (student_id)
teachers (id) ──── teacher_sessions (teacher_id)


Cruce lógico (no FK en BD):
  group_members.username  ←→  students.email   (LOWER comparison)
```

---

## 4. Historial de versiones (migrations)

| Versión | Cambios | Código |
|---|---|---|
| **v1** | Tablas `students`, `sessions` | `onCreate` |
| **v2** | Tablas `teachers`, `teacher_sessions` | `onUpgrade oldVersion < 2` |
| **v3** | Tablas de grupos: `group_categories`, `groups`, `group_members` | `onUpgrade oldVersion < 3` |
| **v4** | Tablas de evaluaciones: `evaluations`, `evaluation_responses` | `onUpgrade oldVersion < 4` |
| **v5** | `ALTER TABLE group_categories ADD COLUMN teacher_id` + `ALTER TABLE evaluations ADD COLUMN teacher_id` (scoping por profesor) | `onUpgrade oldVersion < 5` |

Las versiones anteriores a 5 tienen `teacher_id DEFAULT 0`, lo que significa que todos los datos históricos quedan asignados al "profesor 0" (sin dueño real). Las instalaciones nuevas desde v5 crean todas las tablas directamente con el campo `teacher_id`.

---

## 5. Repositorios y métodos

### `IAuthRepository` → `AuthRepositoryImpl`

| Método | Operación BD |
|---|---|
| `register(name, email, password)` | INSERT en `students`, INSERT OR REPLACE en `sessions` |
| `login(email, password)` | SELECT con hash; INSERT OR REPLACE en `sessions` |
| `getCurrentSession()` | JOIN `sessions` + `students` WHERE `sessions.id = 1` |
| `logout()` | DELETE FROM `sessions` WHERE `id = 1` |

### `ITeacherAuthRepository` → `TeacherAuthRepositoryImpl`

Mismo patrón con tablas `teachers` y `teacher_sessions`.

### `IGroupRepository` → `GroupRepositoryImpl`

| Método | Operación BD |
|---|---|
| `importFromCsv(file, teacherId)` | Parsea CSV; INSERT en `group_categories`, `groups`, `group_members` |
| `getCategories(teacherId)` | SELECT FROM `group_categories` WHERE `teacher_id = ?` |

### `IEvaluationRepository` → `EvaluationRepositoryImpl`

| Método | Operación BD |
|---|---|
| `create(...)` | Verifica duplicado de nombre; INSERT en `evaluations` |
| `rename(evalId, newName, teacherId)` | Verifica duplicado; UPDATE `evaluations` |
| `delete(evalId)` | DELETE en `evaluation_responses` y `evaluations` |
| `getAll(teacherId)` | SELECT con JOIN a `group_categories` WHERE `teacher_id = ?` ORDER BY `created_at DESC` |
| `getGroupResults(evalId)` | 2 queries: promedios por miembro + promedios por criterio/grupo |
| `getEvaluationsForStudent(email)` | JOIN chain: `evaluations → group_categories → groups → group_members` WHERE `username = email` |
| `getLatestForStudent(email)` | Igual + LIMIT 1 |
| `getGroupNameForStudent(evalId, email)` | JOIN para encontrar el grupo del estudiante en esa eval |
| `getPeersForStudent(evalId, email)` | Encuentra el grupo → todos los miembros excepto el propio email |
| `getCoursesForStudent(email)` | JOIN para obtener categorías y grupos del estudiante |
| `saveResponses(...)` | Transacción: INSERT múltiple en `evaluation_responses` (1 fila por criterio) |
| `hasEvaluated(...)` | SELECT COUNT con `eval_id + evaluator_id + evaluated_member_id` |
| `hasCompletedAllPeers(...)` | 2 queries: total peers del grupo + DISTINCT evaluados por este estudiante |
| `getMyResults(evalId, email)` | Encuentra `group_member.id` del estudiante → AVG de scores recibidos por criterio |

---

## 6. Consultas SQL clave

### Obtener evaluaciones de un estudiante
```sql
SELECT DISTINCT e.*, gc.name AS category_name
FROM evaluations e
JOIN group_categories gc ON gc.id = e.category_id
JOIN groups g            ON g.category_id = e.category_id
JOIN group_members gm    ON gm.group_id = g.id
WHERE LOWER(gm.username) = ?
ORDER BY e.created_at DESC
```
Une al estudiante (por email en `group_members.username`) con las evaluaciones que aplican a su categoría de grupo.

### Obtener compañeros de un estudiante en una evaluación
```sql
-- Paso 1: encontrar el grupo del estudiante
SELECT g.id
FROM groups g
JOIN group_members gm ON gm.group_id = g.id
JOIN evaluations e    ON e.category_id = g.category_id
WHERE e.id = ? AND LOWER(gm.username) = ?
LIMIT 1

-- Paso 2: todos los miembros del grupo excepto el estudiante
SELECT * FROM group_members
WHERE group_id = ? AND LOWER(username) != ?
```

### Verificar si un estudiante completó todas sus evaluaciones
```sql
-- Paso 1: peers del estudiante en ese grupo
SELECT id FROM group_members
WHERE group_id = ? AND LOWER(username) != ?
-- → lista de peerIds

-- Paso 2: cuántos de esos peers ya fueron evaluados
SELECT COUNT(DISTINCT evaluated_member_id) AS cnt
FROM evaluation_responses
WHERE eval_id = ? AND evaluator_id = ?
  AND evaluated_member_id IN (?, ?, ...)
```
Si `cnt >= total` y `total > 0` → el estudiante completó la evaluación.

### Resultados por grupo para el profesor
```sql
-- Promedios por miembro
SELECT g.id AS grp_id, g.name AS grp_name,
       gm.id AS mem_id, gm.name AS mem_name,
       COALESCE(AVG(CASE WHEN er.score >= 2 THEN CAST(er.score AS REAL) END), 0.0) AS avg_score
FROM groups g
JOIN evaluations e    ON e.category_id = g.category_id
JOIN group_members gm ON gm.group_id = g.id
LEFT JOIN evaluation_responses er
       ON er.eval_id = e.id
      AND er.evaluated_member_id = gm.id
      AND er.score >= 2
WHERE e.id = ?
GROUP BY g.id, gm.id
ORDER BY g.name, gm.name

-- Promedios por criterio por grupo
SELECT g.id AS grp_id, er.criterion_id,
       AVG(CAST(er.score AS REAL)) AS avg_score
FROM groups g
JOIN evaluations e    ON e.category_id = g.category_id
JOIN group_members gm ON gm.group_id = g.id
JOIN evaluation_responses er
       ON er.eval_id = e.id
      AND er.evaluated_member_id = gm.id
      AND er.score >= 2
WHERE e.id = ?
GROUP BY g.id, er.criterion_id
```

### Resultados personales de un estudiante
```sql
-- Encontrar el/los group_member.id del estudiante en esa eval
SELECT gm.id
FROM group_members gm
JOIN groups g         ON g.id = gm.group_id
JOIN evaluations e    ON e.category_id = g.category_id
WHERE e.id = ? AND LOWER(gm.username) = ?

-- Promedios de scores recibidos, por criterio
SELECT criterion_id, AVG(CAST(score AS REAL)) AS avg_score
FROM evaluation_responses
WHERE eval_id = ? AND evaluated_member_id IN (?)
  AND score >= 2
GROUP BY criterion_id
```

---

## 7. Estado de evaluación por estudiante

Este es un estado **calculado en runtime**, no persistido en la BD. Se almacena en `StudentController.evalStatuses: RxMap<int, EvalStudentStatus>`.

### Enum

```dart
enum EvalStudentStatus {
  activePending,    // isActive=true  && !completedAllPeers
  activeCompleted,  // isActive=true  && completedAllPeers
  closedNotDone,    // isActive=false && !completedAllPeers
  closedCompleted,  // isActive=false && completedAllPeers
}
```

### `isActive` — derivado de BD, calculado en runtime

```dart
// En Evaluation model
bool get isActive => DateTime.now().isBefore(closesAt);
// closesAt viene de evaluation.closes_at (UNIX ms en BD)
```

### `completedAllPeers` — consulta a BD

```
1. Obtener group_id del estudiante para esta evaluación
2. Contar grupo_members del grupo excluyendo al propio estudiante → total
3. Contar DISTINCT evaluated_member_id en evaluation_responses
   donde eval_id=X AND evaluator_id=studentId AND evaluated_member_id IN (peers)
4. completedAllPeers = (done >= total) AND (total > 0)
```

### Máquina de estados

```
                    ┌─────────────────────────────────┐
                    │        EVALUACIÓN CREADA         │
                    │   closes_at = created_at + hours │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │          activePending           │
                    │  isActive=true, done < total     │
                    └──────┬──────────────────────────┘
                           │
          ┌────────────────┤────────────────────────┐
          │ submitEvaluation()                       │ closes_at vence
          │ done >= total                            │ sin haber enviado
          ▼                                          ▼
┌─────────────────────┐                  ┌──────────────────────┐
│   activeCompleted   │                  │    closedNotDone     │
│ isActive=true       │                  │ isActive=false       │
│ done >= total       │                  │ done < total         │
└──────────┬──────────┘                  └──────────────────────┘
           │ closes_at vence
           ▼
┌─────────────────────┐
│   closedCompleted   │
│ isActive=false      │
│ done >= total       │
└─────────────────────┘
```

### Cuándo se carga/refresca

| Evento | Método | Alcance |
|---|---|---|
| Login de estudiante | `loadEvalData()` → `_computeStatuses()` | Todas las evaluaciones del estudiante |
| `submitEvaluation()` | Inline en el método | Solo la evaluación enviada |
| Logout | `_resetEvalState()` → `evalStatuses.clear()` | Limpia todo |

---

## 8. Flujos de datos completos

### 8.1 Registro de estudiante

```
UI: RegisterPage
  → ctrl.register(name, email, password)
  → AuthRepositoryImpl.register(...)
      → SHA-256(password) → hash
      → INSERT INTO students (name, email, password=hash, initials)
      → INSERT OR REPLACE INTO sessions VALUES (1, student_id)
      → returns Student
  → student.value = Student
  → Get.offAllNamed('/student/courses')
  → loadEvalData() se dispara via ever(student, ...)
```

### 8.2 Importar grupos desde CSV (Profesor)

```
UI: TImportPage → FilePicker
  → GroupRepositoryImpl.importFromCsv(file, teacherId)
      → Parsear CSV línea por línea
      → Para cada categoría única:
          INSERT INTO group_categories (name, imported_at, teacher_id)
      → Para cada grupo único dentro de la categoría:
          INSERT INTO groups (category_id, name)
      → Para cada miembro:
          INSERT INTO group_members (group_id, name, username)
  → TeacherController actualiza lista de categorías
```

Formato CSV esperado:
```
category_name,group_name,member_name,member_username
Proyecto Final,Grupo A,Juan Pérez,juan.perez@uni.edu
Proyecto Final,Grupo A,María López,maria.lopez@uni.edu
Proyecto Final,Grupo B,Carlos Ruiz,carlos.ruiz@uni.edu
```

### 8.3 Crear evaluación (Profesor)

```
UI: TNewEvalPage
  → TeacherController.createEvaluation(name, categoryId, hours, visibility)
  → EvaluationRepositoryImpl.create(...)
      → SELECT para verificar nombre duplicado (LOWER(name) = ? AND teacher_id = ?)
      → Si duplicado → throw Exception
      → now = DateTime.now()
      → closesAt = now + Duration(hours: hours)
      → INSERT INTO evaluations (name, category_id, hours, visibility,
                                 created_at, closes_at, teacher_id)
      → SELECT group_categories WHERE id = categoryId → categoryName
      → returns Evaluation
  → evaluations.insert(0, newEval)
  → Get.back()
```

### 8.4 Carga del dashboard de estudiante

```
StudentController.loadEvalData()
  │
  ├─ EvalRepo.getEvaluationsForStudent(email)
  │    → JOIN: evaluations → group_categories → groups → group_members
  │    → evaluations.assignAll(evalList)
  │
  ├─ _computeStatuses(evalList, email, studentId)
  │    Para cada eval:
  │      EvalRepo.hasCompletedAllPeers(evalId, email, studentId)
  │        → query 1: total peers del grupo
  │        → query 2: count DISTINCT evaluados por este estudiante
  │        → completed = done >= total && total > 0
  │      evalStatuses[eval.id] = f(isActive, completed)
  │
  ├─ activeEvalDb.value = primera eval con activePending
  │    (fallback: primera activa, luego primera de cualquier tipo)
  │
  ├─ _loadGroupAndPeers(activeEval, student)
  │    → getGroupNameForStudent → currentGroupName
  │    → getPeersForStudent → lista de Peer
  │    → Para cada peer: hasEvaluated(...) → peer.evaluated = true/false
  │    → peers.assignAll(peerList)
  │
  └─ _loadMyResultsInternal(activeEval.id, email)
       → getMyResults → lista de CriterionResult
       → myResults.assignAll(results)
```

### 8.5 Evaluar un compañero y enviar

```
UI: SPeersPage → tap compañero
  → ctrl.selectPeer(peer)
      → currentPeer.value = peer
      → scores = Map.from(peer.scores)

UI: SPeerScorePage → seleccionar valores
  → ctrl.setScore(criterionId, value)   -- actualiza scores map

UI: tap "Guardar y continuar"
  → ctrl.savePeerScore()
      → peer.scores = Map.from(scores)
      → peer.evaluated = true
      → peers.refresh()
  → Get.offNamed('/student/peers')

UI: SPeersPage → tap "Enviar evaluación completa" (allEvaluated = true)
  → ctrl.submitEvaluation()
      → Para cada peer evaluado con scores no vacíos:
          EvalRepo.saveResponses(evalId, evaluatorStudentId, evaluatedMemberId, scores)
            → transaction: INSERT INTO evaluation_responses × 4 criterios
      → _loadMyResultsInternal(eval.id, email)
      → hasCompletedAllPeers(evalId, email, studentId)
      → evalStatuses[eval.id] = activeCompleted (o closedCompleted si ya venció)
  → Get.offNamed('/student/courses')
```

### 8.6 Consulta de resultados del profesor

```
UI: TResultsPage
  → TeacherController.loadResults(evalId)
  → EvalRepo.getGroupResults(evalId)
      → query 1: AVG score por miembro (solo scores >= 2)
                 LEFT JOIN para incluir miembros sin respuestas (avg=0)
      → query 2: AVG score por criterio por grupo
      → Combina en List<GroupResult>:
          GroupResult {
            name: "Grupo A",
            average: 4.2,
            criteria: [4.5, 4.1, 4.0, 4.3],   // punct, contrib, commit, attitude
            students: [ StudentResult{name, score}, ... ]
          }
  → groupResults.assignAll(results)
```

### 8.7 Restauración de sesión al abrir la app

```
_SplashPage.initState()
  → _resolve()
      → Future.wait([
          StudentController.checkSession(),    // SELECT sessions JOIN students
          TeacherController.checkSession(),    // SELECT teacher_sessions JOIN teachers
        ])
      → si teacher.isLoggedIn  → Get.offAllNamed('/teacher/dash')
        si student.isLoggedIn  → Get.offAllNamed('/student/courses')
        si ninguno             → Get.offAllNamed('/login')
```

---

## Apéndice — Criterios de evaluación (hardcoded)

Los criterios no están en la BD; están definidos en `EvalCriterion.defaults` dentro de `peer_evaluation.dart`:

| criterion_id | label | Niveles (2→5) |
|---|---|---|
| `punct` | Puntualidad | Insuficiente · Básico · Bueno · Excelente |
| `contrib` | Aportes al equipo | Insuficiente · Básico · Bueno · Excelente |
| `commit` | Compromiso | Insuficiente · Básico · Bueno · Excelente |
| `attitude` | Actitud | Insuficiente · Básico · Bueno · Excelente |

La escala válida para cálculo académico es **2–5**. Los valores 0 y 1 están reservados para señales de alerta (pendiente de implementar en la UI actual).

## Apéndice — Colores de criterios en UI

| criterion_id | Color | Constante |
|---|---|---|
| `punct` (índice 0) | Azul | `critBlue = #0EA5E9` |
| `contrib` (índice 1) | Púrpura | `critPurple = #8B5CF6` |
| `commit` (índice 2) | Verde | `critGreen = #059669` |
| `attitude` (índice 3) | Ámbar | `critAmber = #F59E0B` |
