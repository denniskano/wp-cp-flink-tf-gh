#!/usr/bin/env bash
# Plan/apply local: stack temporal-cloud contra YAML de PEVE-orchestration-resources.
set -euo pipefail

STACK="${1:?stack (temporal-cloud)}"
ACTION="${2:-plan}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHDIR="${ROOT}/stacks/${STACK}"
EXTERNO="${EXTERNO:?set EXTERNO al clone de PEVE-orchestration-resources}"
CODAPP="${CODAPP:-PEVE}"
ENV_FOLDER="${ENV_FOLDER:-dev}"

if [[ ! -d "${CHDIR}" ]]; then
  echo "❌ no existe ${CHDIR}"
  exit 1
fi

case "${STACK}" in
  temporal-cloud)
    export TF_VAR_namespaces_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/namespaces"
    export TF_VAR_nexus_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/nexus"
    "${ROOT}/scripts/ci/validate-temporal-yaml.sh" "${CODAPP}" "${ENV_FOLDER}" \
      "${EXTERNO}/${CODAPP}/${ENV_FOLDER}" "${ACTION}"
    CA_OUT="${ROOT}/.temporal-ca"
    mkdir -p "${CA_OUT}"
    if grep -lR 'accepted_client_ca_vault' "${TF_VAR_namespaces_dir}" >/dev/null 2>&1; then
      "${ROOT}/scripts/ci/fetch-temporal-ca-vault.sh" "${TF_VAR_namespaces_dir}" "${CA_OUT}"
    fi
    export TF_VAR_mtls_ca_dir="${CA_OUT}"
    ;;
  *)
    echo "❌ stack no cableado: ${STACK}"
    exit 1
    ;;
esac

cd "${CHDIR}"
terraform init -input=false
terraform "${ACTION}"
