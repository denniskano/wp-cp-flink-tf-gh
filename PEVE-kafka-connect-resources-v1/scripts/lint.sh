#!/usr/bin/env bash
# Lint connects/*.yaml y security/*.yaml con check-jsonschema.
# Uso:
#   ./scripts/lint.sh                         # todo el repo
#   ./scripts/lint.sh PEVE                    # una app (CODAPP)
#   ./scripts/lint.sh PEVE/desa               # un ambiente
#   ./scripts/lint.sh PEVE/desa/use-case-02   # un use-case
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEMA_CONN="${ROOT}/schemas/connects.schema.json"
SCHEMA_SEC="${ROOT}/schemas/security.schema.json"

if ! command -v check-jsonschema >/dev/null 2>&1; then
  echo "Falta check-jsonschema. En el venv o el user:"
  echo "  pip install check-jsonschema"
  exit 1
fi

lint_dir() {
  local schema="$1"
  local dir="$2"
  local label="$3"

  if [[ ! -d "${dir}" ]]; then
    echo "skip ${label}: no existe ${dir}"
    return 0
  fi

  local files=()
  while IFS= read -r -d '' f; do
    files+=("$f")
  done < <(find "${dir}" -maxdepth 1 -type f -name '*.yaml' -print0 | sort -z)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "skip ${label}: sin *.yaml"
    return 0
  fi

  echo "=== ${label} (${#files[@]} yaml) ==="
  check-jsonschema --schemafile "${schema}" "${files[@]}"
}

lint_tree() {
  local base="$1"
  local found=0

  if [[ ! -d "${base}" ]]; then
    echo "No existe ${base#"${ROOT}"/}"
    exit 1
  fi

  while IFS= read -r -d '' dir; do
    found=1
    parent="$(dirname "${dir}")"
    rel="${parent#"${ROOT}"/}"
    lint_dir "${SCHEMA_CONN}" "${parent}/connects" "${rel}/connects"
    lint_dir "${SCHEMA_SEC}" "${parent}/security" "${rel}/security"
  done < <(find "${base}" -type d -name connects -print0 | sort -z)

  if [[ "${found}" -eq 0 ]]; then
    echo "No hay carpetas connects/ bajo ${base#"${ROOT}"/}."
    exit 1
  fi
}

if [[ $# -ge 1 ]]; then
  rel="${1#/}"
  lint_tree "${ROOT}/${rel}"
else
  lint_tree "${ROOT}"
fi
