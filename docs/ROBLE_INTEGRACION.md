# Integracion de ROBLE en PeerUn

## Objetivo
Esta version deja la aplicacion sin dependencia de SQLite para la capa de datos de negocio.
La app usa exclusivamente:
- API ROBLE (`auth` + `database`)
- Paquete Flutter `roble_api_database`
- Variables de entorno con `flutter_dotenv`
- `shared_preferences` solo para persistencia liviana de sesion (tokens y perfil)

## 1) Endpoints revisados de ROBLE

### 1.1 Autenticacion
Base URL:
- `https://roble-api.openlab.uninorte.edu.co/auth/:dbName`

Endpoints clave:
- `POST /:dbName/login`
- `POST /:dbName/refresh-token`
- `POST /:dbName/signup`
- `POST /:dbName/signup-direct`
- `POST /:dbName/logout`
- `GET /:dbName/verify-token`

Notas:
- El token se envia en `Authorization: Bearer <accessToken>`.
- El rol del usuario (`student`, `teacher`, `admin`) se toma del JWT.

### 1.2 Tablas
Base URL:
- `https://roble-api.openlab.uninorte.edu.co/database/:dbName`

Endpoints clave:
- `POST /create-table`
- `PUT /update-table/:tableName`
- `DELETE /delete-table/:tableName`
- `GET /table-data`
- `POST /add-column`
- `POST /update-column/:tableName`
- `POST /drop-column`

### 1.3 Registros (database/records)
Base URL:
- `https://roble-api.openlab.uninorte.edu.co/database/:dbName`

Endpoints clave:
- `POST /insert`
- `GET /read?tableName=...`
- `PUT /update`
- `DELETE /delete`

Estos son los endpoints que usa internamente `roble_api_database` para CRUD remoto.

## 2) Paquetes y configuracion
Dependencias relevantes:
- `roble_api_database`
- `flutter_dotenv`
- `shared_preferences`

Archivo de ejemplo:
- `.env.example`

Variables:
- `ROBLE_DB_NAME`
- `ROBLE_AUTH_BASE_URL` (opcional)
- `ROBLE_DATA_BASE_URL` (opcional)

Carga de variables:
- En `main.dart` se hace `dotenv.load(fileName: '.env')`.
- Si `.env` no existe, hay fallback seguro en `DatabaseService`.

## 3) Arquitectura aplicada (Clean Pragmatic)
Se mantiene separacion por capas:
- `lib/domain`: interfaces y modelos
- `lib/data/services`: cliente remoto y utilidades de sesion
- `lib/data/repositories`: orquestacion de reglas de acceso a datos remotos
- `lib/presentation`: controladores y UI sin acceso directo a API

## 4) Cambios implementados

### 4.1 Servicio central remoto
Archivo:
- `lib/data/services/database_service.dart`

Ahora:
- Configura `RobleApiDataBase` con valores de `.env`.
- Expone wrappers remotos:
  - `robleLogin`, `robleSignupDirect`, `robleLogout`
  - `robleCreate`, `robleRead`, `robleUpdate`, `robleDelete`
  - `robleCreateTable`, `robleGetTableData`
- Extrae claims JWT (`decodeJwtClaims`, `roleFromAccessToken`).
- Persiste sesion en `shared_preferences`:
  - `saveStudentSession/readStudentSession/clearStudentSession`
  - `saveTeacherSession/readTeacherSession/clearTeacherSession`

### 4.2 Repositorios migrados a Roble (sin SQLite)
Archivos:
- `lib/data/repositories/auth_repository_impl.dart`
- `lib/data/repositories/teacher_auth_repository_impl.dart`
- `lib/data/repositories/course_repository_impl.dart`
- `lib/data/repositories/group_repository_impl.dart`
- `lib/data/repositories/evaluation_repository_impl.dart`

Comportamiento:
- Login/register/logout via ROBLE.
- Validacion de rol desde JWT para separar estudiante/profesor.
- CRUD de cursos, categorias, grupos, miembros, evaluaciones y respuestas usando `read/create/update/delete` remotos.
- Joins y agregaciones se hacen en capa repositorio (cliente), respetando interfaces de dominio.

## 5) Eliminacion de SQLite
Se removio la integracion de negocio con SQLite:
- Ya no se usa `sqflite` en `DatabaseService` ni repositorios.
- La persistencia local de sesion usa `shared_preferences`.

## 6) Ejecucion
1. Crear archivo `.env` basado en `.env.example`.
2. Instalar dependencias:
   - `flutter pub get`
3. Ejecutar app:
   - `flutter run`

## 7) Nota de modelo de datos
La logica de repositorios asume tablas remotas usadas por la app actual:
- `courses`
- `group_categories`
- `groups`
- `group_members`
- `evaluations`
- `evaluation_responses`

Si el proyecto ROBLE usa nombres distintos, ajustar los repositorios manteniendo la misma interfaz de dominio.
