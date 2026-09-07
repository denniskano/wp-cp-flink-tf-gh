#!/usr/bin/env bash
# validate-connect-yaml.sh: existencia de connects/ + security/ (sin Confluent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-connect-yaml.sh"
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

echo "== connects/ vacío (plan): debe pasar (apply vacía el use-case) =="
"${VALIDATE}" "${HERE}/fixtures-empty-connects/connects" \
  "${HERE}/fixtures-empty-connects/security" plan \
  || fail "plan con connects/ vacío"
ok "plan vacío permitido"

echo "== connects/ ausente (apply): debe pasar =="
"${VALIDATE}" "${HERE}/no-such-connects" "${HERE}/no-such-security" apply \
  || fail "apply sin connects/"
ok "apply sin connects/ permitido"

echo "== connects/ vacío (pause): debe fallar =="
if "${VALIDATE}" "${HERE}/fixtures-empty-connects/connects" \
     "${HERE}/fixtures-empty-connects/security" pause; then
  fail "pause con connects/ vacío debió fallar"
fi
ok "pause vacío bloqueado"

echo "== security/ ausente con YAML (plan): debe fallar =="
if "${VALIDATE}" "${HERE}/fixtures/connects" "${HERE}/no-such-security" plan; then
  fail "plan sin security/ debió fallar"
fi
ok "security/ ausente bloqueado"

echo "tests/kafka-connect: OK"
