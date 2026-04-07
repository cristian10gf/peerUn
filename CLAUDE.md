# Evalia (peerUn) — Claude Code Context

## Project
Flutter peer-assessment app ("Evalia", package `example`) integrating with **Roble** (BaaS by OpenLab, Uninorte).
Two user roles: **Student** (light/teal theme) and **Teacher** (dark/gold theme).

## Architecture
- **Pragmatic Clean**: View → Controller (GetX) → Repository (no UseCases)
- **GetX**: state (`Rx<T>`, `.obs`, `Obx`), navigation (`Get.offAllNamed`), DI (`Get.put`, `Bindings`)
- **Backend**: Roble API via `roble_api_database` package + direct `http` calls for bulk operations
- Key packages: get ^4.7.3, roble_api_database ^1.0.3, http ^1.6.0, uuid ^4.5.1, shared_preferences, flutter_dotenv, file_picker

## Key Files
```
lib/
  main.dart                                    # App + _AppBindings + _SplashPage
  domain/models/
    student.dart, teacher.dart                 # Auth entities
    course.dart                                # Course, ActiveEvaluation
    peer_evaluation.dart                       # Peer, EvalCriterion, CriterionResult (NO Color fields)
    teacher_data.dart                          # TeacherCourse, GroupResult, StudentResult (NO Color fields)
    group_category.dart                        # GroupMember, CourseGroup, GroupCategory
  domain/repositories/
    i_auth_repository.dart, i_teacher_auth_repository.dart
    i_group_repository.dart                    # getAll, importCsv, delete
  domain/services/
    csv_import_domain_service.dart             # RFC-4180 CSV parser, Brightspace format
  data/services/database/
    database_service.dart                      # Facade — delegates to sub-services
    database_service_auth.dart                 # Login, signup, JWT decode
    database_service_config.dart               # URL building, default password
    database_service_crud.dart                 # CRUD + robleBulkInsert (direct http)
    database_service_session.dart              # SharedPreferences session persistence
  data/services/roble_schema.dart              # Table names, aliases, primary keys
  data/repositories/
    auth_repository_impl.dart
    teacher_auth_repository_impl.dart
    group_repository_impl.dart                 # Optimised importCsv (~15-20 API calls)
  data/utils/
    email_utils.dart, repository_db_utils.dart, value_parsers.dart
  presentation/
    theme/app_colors.dart                      # Student palette (light/teal)
    theme/teacher_colors.dart                  # Teacher palette (dark/gold)
    pages/student/                             # StudentController + student pages
    pages/teacher/                             # TeacherController + teacher pages
    widgets/auth_widgets.dart, teacher_auth_widgets.dart
```

## Domain Rules
- **NO Flutter/Color in domain models** — colors assigned by index in presentation layer
- `EvalCriterion`, `CriterionResult`, `GroupResult`, `StudentResult` have no Color fields
- Colors via local palettes: `_critColors` (student), `_kAvatarColors` (teacher)
- `_tkScore(double v)` helper in `t_results_page.dart` for score-based colors

## Roble API
- Single-record CRUD: delegate to `roble_api_database` package methods
- Bulk insert: `DatabaseServiceCrud.robleBulkInsert()` calls `POST /:dbName/insert` directly via `http`
  - Body: `{ tableName, records: [...] }` | Response: `{ inserted: [...], skipped: [...] }`
- Token management: `DatabaseService.setSessionTokens()` must be called after login and after each
  student signup in `importCsv` to restore teacher context
- Table name resolution: aliases in `RobleSchema.tableAliases` tried sequentially, result cached

## CSV Import Strategy (importCsv)
Optimised from ~165 sequential API calls → ~15-20:
1. Pre-load users, courses, user_course, user_group (4 reads)
2. Phase 1: Parallel signup-direct for new students (concurrency 5)
3. Phase 2: 1 bulk insert → users table
4. Phase 3: 1 create → category
5. Phase 4: G creates → groups (one per group)
6. Phase 5: 1 bulk insert → user_group relations
7. Phase 6: 1 bulk insert → user_course relations
- Brightspace CSV format: 9 cols — col 1=Group Name, col 3=Username, col 5=FirstName, col 6=LastName, col 7=Email
- Prefers col 7 (Email Address) over col 3 (Username) for login email

## GetX Obx Rule
Observables must be accessed **directly inside the Obx closure**, not in child widget `build()` methods.

## Auth
- Passwords hashed with SHA-256 (`crypto` package) in both auth repos
- JWT `sub` claim = auth user ID; `decodeJwtClaims()` available on `DatabaseService`

## Splash Logic
1. Check both sessions in parallel
2. Route: teacher dash → student courses → student login

## Known Pre-existing Issues
- `f_web_authentication/` sub-package has broken dependencies (flex_color_scheme, loggy, etc.) — ignore these in `flutter analyze`
- `flutter analyze` should be run on main lib only for our work
