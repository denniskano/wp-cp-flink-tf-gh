#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-flink-yaml.sh"
GEN_RBAC="${ROOT}/scripts/gen_rbac_flink_dinamic.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp -d)"
trap 'rm -rf "${OUT}"' EXIT

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== fixtures (plan): debe pasar =="
"${VALIDATE}" statements "${HERE}/fixtures/statement" "${HERE}/fixtures/security" plan \
  || fail "fixtures plan"
ok "fixtures plan"

echo "== statements vacío (plan): debe fallar =="
if "${VALIDATE}" statements "${HERE}/fixtures-empty/statement" \
     "${HERE}/fixtures-empty/security" plan; then
  fail "plan con statement/ vacío debió fallar"
fi
ok "plan vacío bloqueado"

echo "== codegen gen_rbac_flink_dinamic.sh =="
if ! command -v yq >/dev/null || ! command -v envsubst >/dev/null || ! command -v jq >/dev/null; then
  echo "⏭️  yq/envsubst/jq no instalados; se omite prueba de codegen"
else
  export CC_SR_PROPERTIES_ID="azccdeu2peve02_bcp"
  export CC_SR_PROPERTIES='{"azccdeu2peve02_bcp":{"sr_properties":"sr_des"},"sr_des":{"schema_registry_id":"lsrc-xxxxx","schema_registry_rest_endpoint":"https://sr.example"}}'
  export HV_PEVE_SECRETS='{"sr_des_api_key":"k","sr_des_api_secret":"s"}'
  (
    cd "${ROOT}"
    "${GEN_RBAC}" \
      "11111111-1111-1111-1111-111111111111" \
      "env-xxxxx" \
      "lkc-xxxxx" \
      "lsrc-xxxxx" \
      "${HERE}/fixtures/security" \
      "${OUT}"
  ) || fail "codegen rbac"
  [[ -f "${OUT}/rbac_flink.tf" ]] || fail "no se escribió rbac_flink.tf"
  [[ -f "${OUT}/data_sa_flink.tf" ]] || fail "no se escribió data_sa_flink.tf"
  grep -q 'FlinkDeveloper' "${OUT}/rbac_flink.tf" || fail "FlinkDeveloper ausente"
  ok "codegen rbac_flink.tf"
fi

echo "tests/flink-statements: OK"
