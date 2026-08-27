#!/usr/bin/env bash
# Plan/apply local contra un stack. Requiere Terraform y credenciales en env.
# Uso:
#   EXTERNO=/path/to/resources CODAPP=PEVE USE_CASE=demo-postgres-01 \
#     ./scripts/local/tf.sh kafka-connect plan
set -euo pipefail

STACK="${1:?stack (kafka-connect|flink-statements|...)}"
ACTION="${2:-plan}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CHDIR="${ROOT}/stacks/${STACK}"
EXTERNO="${EXTERNO:?set EXTERNO al clone del repo de resources}"
CODAPP="${CODAPP:-PEVE}"
USE_CASE="${USE_CASE:?USE_CASE}"
ENV_FOLDER="${ENV_FOLDER:-desa}"

if [[ ! -d "${CHDIR}" ]]; then
  echo "❌ no existe ${CHDIR}"
  exit 1
fi

export TF_VAR_connectors_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/${USE_CASE}/connects"
export TF_VAR_security_dir="${EXTERNO}/${CODAPP}/${ENV_FOLDER}/${USE_CASE}/security"

cd "${CHDIR}"
terraform init -input=false
terraform "${ACTION}"
