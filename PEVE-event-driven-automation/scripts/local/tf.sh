#!/usr/bin/env bash
# Plan/apply local contra un stack. Requiere Terraform y credenciales en env.
# Flink: corre codegen (gen_*_dinamic.sh) antes de terraform.
set -euo pipefail

STACK="${1:?stack (kafka-connect|flink-compute-pool|flink-statements|...)}"
ACTION="${2:-plan}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHDIR="${ROOT}/stacks/${STACK}"
EXTERNO="${EXTERNO:?set EXTERNO al clone del repo de resources}"
CODAPP="${CODAPP:-PEVE}"
ENV_FOLDER="${ENV_FOLDER:-desa}"
ENVIRONMENT_HV="${ENVIRONMENT_HV:-dev}"
export ENVIRONMENT_HV

if [[ ! -d "${CHDIR}" ]]; then
  echo "❌ no existe ${CHDIR}"
  exit 1
fi

# Codegen v2 busca ./resources/template desde el cwd (raíz del repo)
cd "${ROOT}"

case "${STACK}" in
  kafka-connect)
    USE_CASE="${USE_CASE:?USE_CASE}"
    export TF_VAR_connectors_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/${USE_CASE}/connects"
    export TF_VAR_security_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/${USE_CASE}/security"
    ;;
  flink-compute-pool)
    ENVIRONMENT_ID="${ENVIRONMENT_ID:?ENVIRONMENT_ID (env-xxxxx)}"
    "${ROOT}/scripts/gen_cp_flink_dinamic.sh" \
      "${ENVIRONMENT_ID}" \
      "${EXTERNO}/${CODAPP}/ccloud-flink/${ENV_FOLDER}/compute-pool" \
      "${CHDIR}"
    ;;
  flink-statements)
    PIPELINE="${PIPELINE:?PIPELINE}"
    ORGANIZATION_ID="${ORGANIZATION_ID:?ORGANIZATION_ID}"
    ENVIRONMENT_ID="${ENVIRONMENT_ID:?ENVIRONMENT_ID}"
    CATALOG_NAME="${CATALOG_NAME:-bcp_desa}"
    CLUSTER_NAME="${CLUSTER_NAME:-AZURE_EU2_DESA_KAFKA01}"
    CLUSTER_ID="${CLUSTER_ID:-lkc-xzyppq}"
    SCHEMA_REGISTRY_ID="${SCHEMA_REGISTRY_ID:-lsrc-9rgmm7}"
    ENVIRONMENT="${ENVIRONMENT:-DES}"
    FLINK_CREDS_B64="${FLINK_CREDS_B64:-$(printf '%s' '{}' | base64)}"
    "${ROOT}/scripts/gen_rbac_flink_dinamic.sh" \
      "${ORGANIZATION_ID}" \
      "${ENVIRONMENT_ID}" \
      "${CLUSTER_ID}" \
      "${SCHEMA_REGISTRY_ID}" \
      "${EXTERNO}/${CODAPP}/ccloud-flink/${ENV_FOLDER}/${PIPELINE}/security" \
      "${CHDIR}"
    "${ROOT}/scripts/gen_stmt_flink_dinamic.sh" \
      "${ORGANIZATION_ID}" \
      "${ENVIRONMENT_ID}" \
      "${CATALOG_NAME}" \
      "${CLUSTER_NAME}" \
      "${FLINK_CREDS_B64}" \
      "${EXTERNO}/${CODAPP}/ccloud-flink/${ENV_FOLDER}/${PIPELINE}/statement" \
      "${ENVIRONMENT}" \
      "${CHDIR}"
    ;;
  *)
    echo "❌ stack no cableado en tf.sh: ${STACK}"
    exit 1
    ;;
esac

cd "${CHDIR}"
terraform init -input=false
terraform "${ACTION}"
