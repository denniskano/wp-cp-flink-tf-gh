#!/usr/bin/env bash
# Lint connects/ y security/ con JSON Schema.
# Preferido: check-jsonschema. Fallback: Ajv (npm).
# Uso: schema-lint.sh <connectors_dir> [security_dir]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CONNECTORS_DIR="${1:?connectors_dir}"
SECURITY_DIR="${2:-}"

ensure_ajv() {
  if [[ ! -d "${ROOT}/node_modules/ajv" ]]; then
    echo "=== npm install (ajv + js-yaml) ==="
    (cd "${ROOT}" && npm install --no-fund --no-audit)
  fi
}

lint_files() {
  local schema="$1"
  shift
  local files=("$@")

  if command -v check-jsonschema >/dev/null 2>&1; then
    check-jsonschema --schemafile "${schema}" "${files[@]}"
    return
  fi

  if ! command -v node >/dev/null 2>&1; then
    echo "❌ Instala check-jsonschema (pip) o Node.js para Ajv."
    exit 1
  fi
  ensure_ajv
  node "${ROOT}/scripts/ci/ajv-lint.mjs" "${schema}" "${files[@]}"
}

lint_dir() {
  local schema_rel="$1"
  local dir="$2"
  local label="$3"

  if [[ ! -d "${dir}" ]]; then
    echo "schema: ${label} no existe (${dir}); omitido"
    return 0
  fi

  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "${dir}" -maxdepth 1 -type f -name '*.yaml' -print0 | sort -z)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "schema: ${label} sin *.yaml; omitido"
    return 0
  fi

  echo "=== json-schema ${label} (${#files[@]} yaml) ==="
  lint_files "${ROOT}/${schema_rel}" "${files[@]}"
}

lint_dir "schemas/connects.schema.json" "${CONNECTORS_DIR}" "connects"
if [[ -n "${SECURITY_DIR}" ]]; then
  lint_dir "schemas/security.schema.json" "${SECURITY_DIR}" "security"
fi
