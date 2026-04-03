#!/usr/bin/env bash
set -euo pipefail

DB_NAME="evalun_5268a77998"
BASE_URL="https://roble-api.openlab.uninorte.edu.co"

usage() {
  cat <<'EOF'
Uso:
  bash scripts/replicar_db_roble.sh [opciones]

Opciones:
  --login-first          Fuerza login en /auth/:dbName/login antes de crear tablas.
  --access-token TOKEN   Usa este token directamente.
  --email EMAIL          Email para login.
  --password PASSWORD    Password para login.
  -h, --help             Muestra esta ayuda.

Tambien puedes usar variables de entorno: ACCESS_TOKEN, API_EMAIL, API_PASSWORD.
EOF
}

LOGIN_FIRST=false
ACCESS_TOKEN="${ACCESS_TOKEN:-}"
API_EMAIL="${API_EMAIL:-}"
API_PASSWORD="${API_PASSWORD:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --login-first)
      LOGIN_FIRST=true
      shift
      ;;
    --access-token)
      ACCESS_TOKEN="${2:-}"
      shift 2
      ;;
    --email)
      API_EMAIL="${2:-}"
      shift 2
      ;;
    --password)
      API_PASSWORD="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Opcion no reconocida: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ "$LOGIN_FIRST" = true ] || [ -z "$ACCESS_TOKEN" ]; then
  if [ -z "$API_EMAIL" ]; then
    read -r -p "Email para login: " API_EMAIL
  fi

  if [ -z "$API_PASSWORD" ]; then
    read -r -s -p "Password para login: " API_PASSWORD
    echo
  fi

  LOGIN_RESPONSE=$(curl -sS -X POST "$BASE_URL/auth/$DB_NAME/login" \
    -H "Content-Type: application/json" \
    --data-raw "{\"email\":\"$API_EMAIL\",\"password\":\"$API_PASSWORD\"}")

  ACCESS_TOKEN=$(printf '%s' "$LOGIN_RESPONSE" | sed -n 's/.*"accessToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

  if [ -z "$ACCESS_TOKEN" ]; then
    echo "No fue posible obtener accessToken. Respuesta login: $LOGIN_RESPONSE" >&2
    exit 1
  fi
fi

echo "Usando DB: $DB_NAME"

echo "[1/10] Creando tabla users"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "users",
    "description": "Usuarios del sistema",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "name", "type": "varchar" },
      { "name": "email", "type": "varchar" },
      { "name": "password", "type": "varchar" },
      { "name": "role", "type": "varchar" },
      { "name": "created_at", "type": "timestamp" }
    ]
  }'
echo

echo "[2/10] Creando tabla courses"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "courses",
    "description": "Cursos",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "name", "type": "varchar" },
      { "name": "description", "type": "text" },
      { "name": "created_by", "type": "integer", "isNullable": false },
      { "name": "created_at", "type": "timestamp" }
    ]
  }'
echo

echo "[3/10] Creando tabla categories"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "categories",
    "description": "Categorias de evaluacion por curso",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "name", "type": "varchar" },
      { "name": "description", "type": "text" },
      { "name": "course_id", "type": "integer", "isNullable": false }
    ]
  }'
echo

echo "[4/10] Creando tabla groups"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "groups",
    "description": "Equipos dentro de cursos",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "name", "type": "varchar" },
      { "name": "created_at", "type": "timestamp" },
      { "name": "category_id", "type": "integer", "isNullable": false }
    ]
  }'
echo

echo "[5/10] Creando tabla user_course"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "user_course",
    "description": "Relacion muchos a muchos entre usuarios y cursos",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "course_id", "type": "integer", "isNullable": false },
      { "name": "user_id", "type": "integer", "isNullable": false },
      { "name": "role", "type": "varchar", "isNullable": false }
    ]
  }'
echo

echo "[6/10] Creando tabla user_group"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "user_group",
    "description": "Miembros de equipos",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "user_id", "type": "integer" },
      { "name": "group_id", "type": "integer", "isNullable": false }
    ]
  }'
echo

echo "[7/10] Creando tabla evaluations"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "evaluations",
    "description": "Evaluaciones por categoria",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "created_by", "type": "integer", "isNullable": false },
      { "name": "category_id", "type": "integer", "isNullable": false },
      { "name": "title", "type": "varchar" },
      { "name": "description", "type": "text" },
      { "name": "start_date", "type": "timestamp" },
      { "name": "end_date", "type": "timestamp" }
    ]
  }'
echo

echo "[8/10] Creando tabla criterium"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "criterium",
    "description": "Criterios de evaluacion",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "name", "type": "varchar" },
      { "name": "description", "type": "text" },
      { "name": "max_score", "type": "integer" }
    ]
  }'
echo

echo "[9/10] Creando tabla resultEvaluation"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "resultEvaluation",
    "description": "Resultado de evaluacion A -> B",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "evaluation_id", "type": "integer", "isNullable": false },
      { "name": "evaluator_id", "type": "integer", "isNullable": false },
      { "name": "evaluated_id", "type": "integer", "isNullable": false },
      { "name": "comment", "type": "text" },
      { "name": "created_at", "type": "timestamp" },
      { "name": "group_id", "type": "integer", "isNullable": false }
    ]
  }'
echo

echo "[10/10] Creando tabla result_criterium"
curl -sS -X POST "$BASE_URL/database/$DB_NAME/create-table" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  --data-raw '{
    "tableName": "result_criterium",
    "description": "Puntaje por criterio",
    "columns": [
      { "name": "id", "type": "integer", "isPrimary": true, "isNullable": false },
      { "name": "result_id", "type": "integer", "isNullable": false },
      { "name": "criterium_id", "type": "integer", "isNullable": false },
      { "name": "score", "type": "integer" }
    ]
  }'
echo

echo "Replica de estructura finalizada."
