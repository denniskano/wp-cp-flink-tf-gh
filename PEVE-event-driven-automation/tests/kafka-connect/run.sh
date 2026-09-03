#!/usr/bin/env bash
# Contratos de validate-yaml.sh (sin Terraform / Confluent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-yaml.sh"
SCHEMA="${ROOT}/scripts/ci/schema-lint.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== fixtures (plan): debe pasar =="
"${VALIDATE}" "${HERE}/fixtures/connects" "${HERE}/fixtures/security" plan \
  || fail "fixtures plan"
ok "fixtures plan"

echo "== fixtures (destroy): debe pasar =="
"${VALIDATE}" "${HERE}/fixtures/connects" "${HERE}/fixtures/security" destroy \
  || fail "fixtures destroy"
ok "fixtures destroy"

echo "== connects/ vacío (plan): debe fallar =="
if "${VALIDATE}" "${HERE}/fixtures-empty-connects/connects" \
     "${HERE}/fixtures-empty-connects/security" plan; then
  fail "plan con connects/ vacío debió fallar"
fi
ok "plan vacío bloqueado"

echo "== connects/ vacío (destroy): debe pasar =="
"${VALIDATE}" "${HERE}/fixtures-empty-connects/connects" \
  "${HERE}/fixtures-empty-connects/security" destroy \
  || fail "destroy con connects/ vacío"
ok "destroy vacío permitido"

echo "== security/ ausente (plan): debe fallar =="
if "${VALIDATE}" "${HERE}/fixtures/connects" "${HERE}/no-such-security" plan; then
  fail "plan sin security/ debió fallar"
fi
ok "security/ ausente bloqueado"

echo "== json-schema fixtures: debe pasar =="
"${SCHEMA}" "${HERE}/fixtures/connects" "${HERE}/fixtures/security" \
  || fail "json-schema fixtures"
ok "json-schema fixtures"

echo "== json-schema connects inválido: debe fallar =="
if "${SCHEMA}" "${HERE}/fixtures-invalid-connects"; then
  fail "schema debió fallar con kafka.auth.mode inválido"
fi
ok "json-schema connects inválido bloqueado"

echo "== json-schema security inválido: debe fallar =="
if "${SCHEMA}" "${HERE}/fixtures/connects" "${HERE}/fixtures-invalid-security"; then
  fail "schema debió fallar con resource_type=grup"
fi
ok "json-schema security inválido bloqueado"

echo "tests/kafka-connect: OK"
