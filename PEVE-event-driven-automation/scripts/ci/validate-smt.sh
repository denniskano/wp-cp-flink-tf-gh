#!/usr/bin/env bash
# Valida {CODAPP}/{env}/smt.yaml (existencia + name/url). Sin Confluent.
# Ausente = OK (la app no usa Custom SMT).
# Uso: validate-smt.sh <smt_file>
set -euo pipefail

SMT_FILE="${1:?smt_file}"

if [[ ! -f "${SMT_FILE}" ]]; then
  echo "OK smt.yaml ausente (sin Custom SMT)"
  exit 0
fi

if [[ ! -s "${SMT_FILE}" ]]; then
  echo "❌ ${SMT_FILE} está vacío"
  exit 1
fi

if ! grep -qE '^artifacts:' "${SMT_FILE}"; then
  echo "❌ ${SMT_FILE}: falta artifacts:"
  exit 1
fi

if ! grep -qE '^[[:space:]]+-?[[:space:]]*name:' "${SMT_FILE}"; then
  echo "❌ ${SMT_FILE}: cada artifact necesita name"
  exit 1
fi

if ! grep -qE '^[[:space:]]+url:' "${SMT_FILE}"; then
  echo "❌ ${SMT_FILE}: cada artifact necesita url (transformer_url de Artifactory)"
  exit 1
fi

echo "OK smt_file=${SMT_FILE}"
