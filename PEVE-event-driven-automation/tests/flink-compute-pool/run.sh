#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-flink-yaml.sh"
GEN="${ROOT}/scripts/gen_cp_flink_dinamic.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "${OUT}"' EXIT

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== fixtures (plan): debe pasar =="
"${VALIDATE}" pools "${HERE}/fixtures" plan || fail "fixtures plan"
ok "fixtures plan"

echo "== fixtures (destroy): debe pasar =="
"${VALIDATE}" pools "${HERE}/fixtures" destroy || fail "fixtures destroy"
ok "fixtures destroy"

echo "== compute-pool/ vacío (plan): debe fallar =="
if "${VALIDATE}" pools "${HERE}/fixtures-empty" plan; then
  fail "plan con compute-pool/ vacío debió fallar"
fi
ok "plan vacío bloqueado"

echo "== codegen gen_cp_flink_dinamic.sh =="
if ! command -v yq >/dev/null || ! command -v envsubst >/dev/null; then
  echo "⏭️  yq/envsubst no instalados; se omite prueba de codegen"
else
  export ENVIRONMENT_HV=dev
  (
    cd "${ROOT}"
    "${GEN}" "env-xxxxx" "${HERE}/fixtures" "${OUT}"
  ) || fail "codegen"
  [[ -f "${OUT}/cp_flink.tf" ]] || fail "no se escribió cp_flink.tf"
  grep -q 'CP_AZC_EU2_DES_PEVE_01' "${OUT}/cp_flink.tf" || fail "pool_name ausente en generado"
  ok "codegen cp_flink.tf"
fi

echo "tests/flink-compute-pool: OK"
