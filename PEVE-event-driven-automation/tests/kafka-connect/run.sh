#!/usr/bin/env bash
# validate-yaml.sh: existencia de connects/ + security/ (sin Confluent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-yaml.sh"
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

echo "tests/kafka-connect: OK"
