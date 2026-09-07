#!/usr/bin/env bash
# validate-smt.sh: {CODAPP}/{env}/smt.yaml (sin Confluent).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-smt.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== fixture válido: debe pasar =="
"${VALIDATE}" "${HERE}/fixtures/smt.yaml" || fail "fixture válido"
ok "fixture válido"

echo "== archivo ausente: debe pasar =="
"${VALIDATE}" "${HERE}/no-such-smt.yaml" || fail "ausente debió pasar"
ok "ausente permitido"

echo "== sin url: debe fallar =="
if "${VALIDATE}" "${HERE}/fixtures-no-url/smt.yaml"; then
  fail "sin url debió fallar"
fi
ok "sin url bloqueado"

echo "tests/connect-plugins: OK"
