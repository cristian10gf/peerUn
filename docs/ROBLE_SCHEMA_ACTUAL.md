# Estado actual del esquema ROBLE (peerUn)

Fecha de levantamiento: 2026-03-28
Fuente: capturas del panel Database Tables de ROBLE compartidas en esta conversacion.

## Resumen ejecutivo

- Todas las tablas muestran la columna `_id` (tipo `character varying`, formato `varchar`, no nullable).
- En tablas de negocio (no M:N), tambien existe una llave custom con patron `<tabla>_id`.
- Segun validacion funcional del equipo, las tablas M:N son las unicas donde la llave primaria real es `_id`.
- En el resto, la identidad de negocio principal se maneja con la llave custom `<tabla>_id`.

## Convenciones de lectura

- `Nullable: No` = icono X en el panel.
- `Nullable: Si` = icono check en el panel.

## Tablas y campos

### user

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| user_id | character varying | varchar | No |
| name | character varying | varchar | No |
| email | character varying | varchar | No |
| role | character varying | varchar | No |
| created_at | timestamp without time zone | timestamp | Si |

Notas:
- Tabla de negocio con llave custom `user_id`.

### course

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| course_id | character varying | varchar | No |
| name | character varying | varchar | No |
| nrc | character varying | varchar | Si |
| description | text | text | Si |
| created_at | timestamp without time zone | timestamp | Si |
| created_by | character varying | varchar | No |

Notas:
- Tabla de negocio con llave custom `course_id`.

### category

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| category_id | character varying | varchar | No |
| name | character varying | varchar | No |
| description | character varying | varchar | No |
| course_id | character varying | varchar | No |

Notas:
- Tabla de negocio con llave custom `category_id`.

### group

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| group_id | character varying | varchar | No |
| name | character varying | varchar | No |
| category_id | character varying | varchar | No |
| created_at | timestamp without time zone | timestamp | Si |

Notas:
- Tabla de negocio con llave custom `group_id`.

### user_course (M:N)

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| course_id | character varying | varchar | No |
| user_id | character varying | varchar | No |
| role | character varying | varchar | No |

Notas:
- Tabla de relacion M:N.
- En esta tabla se usa `_id` como llave primaria.

### user_group (M:N)

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| user_id | character varying | varchar | No |
| group_id | character varying | varchar | No |

Notas:
- Tabla de relacion M:N.
- En esta tabla se usa `_id` como llave primaria.

### evaluation

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| evaluation_id | character varying | varchar | No |
| title | character varying | varchar | No |
| description | text | text | No |
| start_date | timestamp without time zone | timestamp | No |
| end_date | timestamp without time zone | timestamp | No |
| category_id | character varying | varchar | No |
| created_by | character varying | varchar | No |

Notas:
- Tabla de negocio con llave custom `evaluation_id`.

### criterium

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| criterium_id | character varying | varchar | No |
| name | character varying | varchar | No |
| description | text | text | No |
| max_score | bigint | int8 | No |

Notas:
- Tabla de negocio con llave custom `criterium_id`.

### evaluation_criterium

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| evaluation_id | character varying | varchar | No |
| criterium_id | character varying | varchar | No |

Notas:
- Tabla puente entre evaluaciones y criterios.

### resultEvaluation

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| resultEvaluation_id | character varying | varchar | No |
| evaluation_id | character varying | varchar | No |
| evaluator_id | character varying | varchar | No |
| evaluated_id | character varying | varchar | No |
| comment | text | text | Si |
| created_at | timestamp without time zone | timestamp | No |
| group_id | character varying | varchar | No |

Notas:
- Tabla de negocio con llave custom `resultEvaluation_id`.

### result_criterium

| Campo | Data type | Format | Nullable |
|---|---|---|---|
| _id | character varying | varchar | No |
| result_id | character varying | varchar | No |
| criterium_id | character varying | varchar | No |
| score | bigint | int8 | No |

Notas:
- Tabla de detalle de resultados por criterio.

## Implicaciones para la capa de datos de peerUn

1. Para tablas de negocio, usar `<tabla>_id` como identidad canonica de dominio (joins, filtros funcionales y referencias entre tablas).
2. Reservar `_id` para operaciones tecnicas de fila cuando el endpoint de ROBLE lo requiera (por ejemplo update/delete por idColumn).
3. Evitar conversiones forzadas de ids a entero en tablas con ids `varchar`; mantener ids como `String` de punta a punta para evitar colisiones o mapeos no deterministas.
4. En importacion CSV, la optimizacion principal sigue siendo reducir roundtrips: cache de usuarios/relaciones, deduplicacion por email+grupo, y chequeos de existencia de tabla una sola vez por corrida.

## Diferencias importantes frente a supuestos previos

- No asumir `id` entero autoincremental como clave funcional en todas las tablas.
- No asumir que `_id` representa siempre la clave de negocio.
- En M:N (`user_course`, `user_group`) si aplica usar `_id` como PK de fila.
