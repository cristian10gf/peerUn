# DATABASE.md - Base de Datos Actual (DBML + Roble)

> Fuente de verdad del modelo: `docs/db.dbml`
> Motor objetivo: PostgreSQL (expuesto por Roble API)
> Acceso de la app: remoto por API (sin SQLite local de negocio)

---

## 1. Resumen de la arquitectura de datos

La app trabaja con una base remota en Roble y sigue esta separacion:

- `lib/domain`: contratos e interfaces (reglas de negocio)
- `lib/data/services`: cliente Roble + manejo de sesion local liviana
- `lib/data/repositories`: orquestacion de lecturas/escrituras
- `lib/presentation`: controladores y UI

No se usa `sqflite` para persistencia de entidades de negocio. Solo se conserva almacenamiento liviano de sesion mediante `shared_preferences`.

---

## 2. Esquema actual (segun db.dbml)

Archivo: `docs/db.dbml`

### 2.1 Tablas

- `users`
  - `id` PK
  - `name`
  - `email` unique
  - `password`
  - `role` (`student` | `teacher` | `admin`)
  - `created_at` default `now()`

- `courses`
  - `id` PK
  - `name`
  - `description`
  - `created_by` FK -> `users.id` (not null)
  - `created_at` default `now()`

- `categories`
  - `id` PK
  - `name`
  - `description`
  - `course_id` FK -> `courses.id` (not null)

- `groups`
  - `id` PK
  - `name`
  - `created_at`
  - `category_id` FK -> `categories.id` (not null)

- `user_course`
  - `id` PK
  - `course_id` FK -> `courses.id` (not null)
  - `user_id` FK -> `users.id` (not null)
  - `role` (`student` | `teacher`) not null

- `user_group`
  - `id` PK
  - `user_id` FK -> `users.id`
  - `group_id` FK -> `groups.id` (not null)

- `evaluations`
  - `id` PK
  - `created_by` FK -> `users.id` (not null)
  - `category_id` FK -> `categories.id` (not null)
  - `title`
  - `description`
  - `start_date`
  - `end_date`

- `criterium`
  - `id` PK
  - `name`
  - `description`
  - `max_score`

- `resultEvaluation`
  - `id` PK
  - `evaluation_id` FK -> `evaluations.id` (not null)
  - `evaluator_id` FK -> `users.id` (not null)
  - `evaluated_id` FK -> `users.id` (not null)
  - `comment`
  - `created_at` default `now()`
  - `group_id` FK -> `groups.id` (not null)

- `result_criterium`
  - `id` PK
  - `result_id` FK -> `resultEvaluation.id` (not null)
  - `criterium_id` FK -> `criterium.id` (not null)
  - `score`

### 2.2 Relaciones clave

- Un `course` es creado por un `user`.
- Un `course` tiene muchas `categories`.
- Una `category` tiene muchos `groups`.
- `user_course` modela membresia y rol por curso.
- `user_group` modela membresia de usuarios por grupo.
- Una `evaluation` pertenece a una `category` y fue creada por un `user`.
- `resultEvaluation` representa una evaluacion de A -> B dentro de una evaluacion y grupo.
- `result_criterium` guarda puntajes por criterio de cada resultado.

---

## 3. Integracion Roble (servicios)

Documentacion oficial usada:

- Autenticacion: `https://roble.openlab.uninorte.edu.co/docs/autenticacion`
- Tablas: `https://roble.openlab.uninorte.edu.co/docs/database`
- Registros CRUD: `https://roble.openlab.uninorte.edu.co/docs/database/records`

### 3.1 Endpoints de autenticacion

Base:

- `https://roble-api.openlab.uninorte.edu.co/auth/:dbName`

Principales:

- `POST /login`
- `POST /refresh-token`
- `POST /signup`
- `POST /signup-direct`
- `POST /logout`
- `GET /verify-token`

### 3.2 Endpoints de estructura de tablas

Base:

- `https://roble-api.openlab.uninorte.edu.co/database/:dbName`

Principales:

- `POST /create-table`
- `PUT /update-table/:tableName`
- `DELETE /delete-table/:tableName`
- `GET /table-data`
- `POST /add-column`
- `POST /update-column/:tableName`
- `POST /drop-column`

### 3.3 Endpoints de datos (records)

- `POST /insert`
- `GET /read?tableName=...`
- `PUT /update`
- `DELETE /delete`

---

## 4. Cliente Flutter usado

Paquete:

- `roble_api_database`

Configuracion en el servicio de datos:

- Archivo: `lib/data/services/database_service.dart`
- Se inicializa `RobleApiDataBase` con `authUrl` y `dataUrl`.
- Se exponen wrappers para auth y CRUD remoto.

### 4.1 Variables de entorno sensibles

Se usan variables de entorno con `flutter_dotenv`:

- `ROBLE_DB_NAME`
- `ROBLE_AUTH_BASE_URL` (opcional)
- `ROBLE_DATA_BASE_URL` (opcional)

Archivo plantilla:

- `.env.example`

Carga:

- `lib/main.dart` hace `dotenv.load(fileName: '.env')`.

---

## 5. Responsabilidades por capa (actual)

### 5.1 Service

`lib/data/services/database_service.dart`

Responsable de:

- crear el cliente Roble
- ejecutar auth remota
- ejecutar CRUD remoto
- decodificar JWT para obtener `role`
- guardar/leer sesion local liviana (tokens y perfil)

### 5.2 Repositories

Responsables de:

- convertir filas remotas a modelos de dominio
- resolver joins en cliente cuando el endpoint devuelve datos planos
- aplicar reglas de negocio (duplicados, filtros por rol, etc.)

### 5.3 Controllers/UI

- no llaman API directamente
- consumen interfaces del dominio

---

## 6. Consideraciones importantes

1. `db.dbml` define el modelo logico esperado.
2. Roble API documentada no siempre expone operaciones explicitas para todas las constraints SQL avanzadas (por ejemplo, crear FK/UNIQUE por endpoint de forma detallada).
3. Por eso, la app aplica reglas adicionales en repositorios para garantizar consistencia funcional.
4. Si se cambia el DBML, actualizar de forma coordinada:
   - script/flujo de creacion de tablas
   - repositorios que mapean campos
   - esta documentacion

---

## 7. Checklist de consistencia

- El modelo de `docs/db.dbml` es la referencia principal.
- La integracion de app usa solo Roble API para negocio.
- `sqlite` no participa en persistencia de entidades de dominio.
- Variables sensibles se leen desde `.env` via `flutter_dotenv`.
