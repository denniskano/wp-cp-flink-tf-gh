#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-flink-yaml.sh"
GEN_RBAC="${ROOT}/scripts/gen_rbac_flink_dinamic.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
# Snapshot de PEVE-stream-processing-resources-v2/PEVE + extras once/ignore/versioned.
PIPE="${HERE}/fixtures/PEVE/desa/pipeline-nombre-caso-negocio-compras-04"
STMT="${PIPE}/statement"
SEC="${PIPE}/security"
OUT="$(mktemp -d)"
trap 'rm -rf "${OUT}"' EXIT

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== fixtures (plan): debe pasar =="
"${VALIDATE}" statements "${STMT}" "${SEC}" plan \
  || fail "fixtures plan"
ok "fixtures plan"

echo "== statements vacío (plan): debe fallar =="
if "${VALIDATE}" statements "${HERE}/fixtures-empty/statement" \
     "${HERE}/fixtures-empty/security" plan; then
  fail "plan con statement/ vacío debió fallar"
fi
ok "plan vacío bloqueado"

echo "== apply inválido: debe fallar =="
BAD="$(mktemp -d)"
mkdir -p "${BAD}/ddl" "${BAD}/dml" "${BAD}/security"
printf '%s\n' 'statement-name: x' 'apply: nope' 'statement: |' '  SELECT 1' > "${BAD}/ddl/bad.yaml"
if "${VALIDATE}" statements "${BAD}" "${BAD}/security" plan; then
  fail "apply inválido debió fallar"
fi
ok "apply inválido bloqueado"

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
      "${SEC}" \
      "${OUT}"
  ) || fail "codegen rbac"
  [[ -f "${OUT}/rbac_flink.tf" ]] || fail "no se escribió rbac_flink.tf"
  [[ -f "${OUT}/data_sa_flink.tf" ]] || fail "no se escribió data_sa_flink.tf"
  [[ -f "${OUT}/data_cp_flink.tf" ]] || fail "no se escribió data_cp_flink.tf (pools del YAML RBAC)"
  grep -q 'data "confluent_flink_compute_pool"' "${OUT}/data_cp_flink.tf" \
    || fail "RBAC sin data.confluent_flink_compute_pool"
  grep -q 'FlinkDeveloper' "${OUT}/rbac_flink.tf" || fail "FlinkDeveloper ausente"
  grep -q 'SA_AZC_DES_PEVE_CDPEVEFL_04' "${OUT}/rbac_flink.tf" \
    || fail "SA de compras-04 ausente en rbac"
  ok "codegen rbac_flink.tf"
fi

echo "== codegen gen_stmt (properties + once) =="
if ! command -v envsubst >/dev/null || ! command -v jq >/dev/null; then
  echo "⏭️  envsubst/jq no instalados; se omite prueba de gen_stmt"
else
  GEN_STMT="${ROOT}/scripts/gen_stmt_flink_dinamic.sh"
  CREDS_JSON='{"SA_AZC_DES_APPV_CDPEVEFL_01/AK_AZC_DES_APPV_FLINK_CDPEVEFL_01":{"key":"k","secret":"s"},"SA_AZC_DES_APPV_PEVEMQFL_02/AK_AZC_DES_APPV_FLINK_PEVEMQFL_01":{"key":"k","secret":"s"},"SA_AZC_DES_PEVE_PEVEMQFL_03/AK_AZC_DES_PEVE_FLINK_PEVEMQFL_01":{"key":"k","secret":"s"},"SA_AZC_DES_PEVE_CDPEVEFL_04/AK_AZC_DES_PEVE_FLINK_CDPEVEFL_01":{"key":"k","secret":"s"}}'
  CREDS_B64="$(printf '%s' "${CREDS_JSON}" | base64)"
  unset IS_ONLY_DDL
  (
    cd "${ROOT}"
    "${GEN_STMT}" \
      "11111111-1111-1111-1111-111111111111" \
      "env-xxxxx" \
      "bcp_desa" \
      "AZURE_EU2_DESA_KAFKA01" \
      "${CREDS_B64}" \
      "${STMT}" \
      "DES" \
      "${OUT}"
  ) || fail "codegen stmt"
  [[ -f "${OUT}/stmt_flink.tf" ]] || fail "no se escribió stmt_flink.tf"
  grep -q 'sql.tables.initial-offset-from' "${OUT}/stmt_flink.tf" || fail "properties no llegaron al HCL"
  grep -q 'terraform_data' "${OUT}/stmt_flink.tf" || fail "apply: once no generó terraform_data"
  grep -q 'apply-once.sh' "${OUT}/stmt_flink.tf" || fail "once sin apply-once.sh"
  grep -q '# apply: ignore  statement-ddl-legacy-ignored' "${OUT}/stmt_flink.tf" \
    || fail "apply: ignore no dejó el comentario de skip"
  if grep -q 'statement_statement-ddl-legacy-ignored\|once_statement-ddl-legacy-ignored' "${OUT}/stmt_flink.tf"; then
    fail "apply: ignore no debe generar resource"
  fi
  grep -q 'statement-ddl-create-azc-peve-poc-flink-internal' "${OUT}/stmt_flink.tf" \
    || fail "DDL real de compras-04 ausente"
  grep -q 'statement-dml-insert-internal-from-input-compra' "${OUT}/stmt_flink.tf" \
    || fail "DML real de compras-04 ausente"
  grep -q 'rowtime' "${OUT}/stmt_flink.tf" || fail "envsubst se comió \$rowtime del YAML PEVE"
  ok "codegen stmt properties + once + ignore"

  echo "== codegen gen_stmt IS_ONLY_DDL=false (once en state DML) =="
  OUT_DML="$(mktemp -d)"
  export IS_ONLY_DDL=false
  (
    cd "${ROOT}"
    "${GEN_STMT}" \
      "11111111-1111-1111-1111-111111111111" \
      "env-xxxxx" \
      "bcp_desa" \
      "AZURE_EU2_DESA_KAFKA01" \
      "${CREDS_B64}" \
      "${STMT}" \
      "DES" \
      "${OUT_DML}"
  ) || fail "codegen stmt IS_ONLY_DDL=false"
  grep -q 'terraform_data.once_statement-ddl-alter-headers-once\|resource "terraform_data" "once_statement-ddl-alter-headers-once"' \
    "${OUT_DML}/stmt_flink.tf" || fail "pase DML no persistió el marcador once"
  if grep -q 'statement_statement-ddl-create-azc-peve-poc-input-compra' "${OUT_DML}/stmt_flink.tf"; then
    fail "pase DML no debe generar DDL managed"
  fi
  grep -q 'statement-dml-insert-internal-v2' "${OUT_DML}/stmt_flink.tf" || fail "pase DML sin DML"
  ok "codegen stmt IS_ONLY_DDL=false persistió once"

  echo "== codegen gen_stmt IS_ONLY_DDL=true (solo DDL) =="
  OUT_DDL="$(mktemp -d)"
  export IS_ONLY_DDL=true
  (
    cd "${ROOT}"
    "${GEN_STMT}" \
      "11111111-1111-1111-1111-111111111111" \
      "env-xxxxx" \
      "bcp_desa" \
      "AZURE_EU2_DESA_KAFKA01" \
      "${CREDS_B64}" \
      "${STMT}" \
      "DES" \
      "${OUT_DDL}"
  ) || fail "codegen stmt IS_ONLY_DDL=true"
  grep -q 'resource "terraform_data" "once_statement-ddl-alter-headers-once"' \
    "${OUT_DDL}/stmt_flink.tf" || fail "pase DDL sin marcador once"
  grep -q 'statement-ddl-create-azc-peve-poc-input-compra' "${OUT_DDL}/stmt_flink.tf" \
    || fail "pase DDL sin CREATE managed"
  if grep -q 'statement-dml-insert-internal' "${OUT_DDL}/stmt_flink.tf"; then
    fail "pase DDL no debe generar DML"
  fi
  grep -q 'rest_endpoint = var.flink_private_rest_endpoint' "${OUT_DDL}/stmt_flink.tf" \
    || fail "rest_endpoint debe ser solo el Private Link (sin REST público)"
  ok "codegen stmt IS_ONLY_DDL=true solo DDL"
  unset IS_ONLY_DDL
  rm -rf "${OUT_DML}" "${OUT_DDL}"
fi

echo "tests/flink-statements: OK"
