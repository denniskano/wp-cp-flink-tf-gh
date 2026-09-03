#!/usr/bin/env bash
# Valida existencia de YAML Flink (no la forma; eso sería JSON Schema).
# Uso:
#   validate-flink-yaml.sh pools <compute_pools_dir> <action>
#   validate-flink-yaml.sh statements <statements_dir> <security_dir> <action>
set -euo pipefail

KIND="${1:?kind (pools|statements)}"
ACTION="${*: -1}"

count_yaml() {
  local dir="$1"
  if [[ ! -d "${dir}" ]]; then
    echo 0
    return
  fi
  find "${dir}" -maxdepth 1 -type f -name '*.yaml' | wc -l | tr -d ' '
}

if [[ "${KIND}" == "pools" ]]; then
  DIR="${2:?compute_pools_dir}"
  if [[ ! -d "${DIR}" ]]; then
    if [[ "${ACTION}" == "destroy" ]]; then
      echo "compute-pool/ ausente; destroy continúa."
      exit 0
    fi
    echo "❌ no existe ${DIR}"
    exit 1
  fi
  N="$(count_yaml "${DIR}")"
  if [[ "${N}" -eq 0 && "${ACTION}" != "destroy" ]]; then
    echo "❌ compute-pool/ sin YAML"
    exit 1
  fi
  echo "OK compute-pool yaml=${N} dir=${DIR}"
  exit 0
fi

if [[ "${KIND}" != "statements" ]]; then
  echo "❌ kind debe ser pools o statements"
  exit 1
fi

STATEMENTS_DIR="${2:?statements_dir}"
SECURITY_DIR="${3:?security_dir}"

if [[ ! -d "${STATEMENTS_DIR}" ]]; then
  if [[ "${ACTION}" == "destroy" ]]; then
    echo "statement/ ausente; destroy continúa."
    exit 0
  fi
  echo "❌ no existe ${STATEMENTS_DIR}"
  exit 1
fi

DDL_N="$(count_yaml "${STATEMENTS_DIR}/ddl")"
DML_N="$(count_yaml "${STATEMENTS_DIR}/dml")"
TOTAL=$((DDL_N + DML_N))

if [[ "${TOTAL}" -eq 0 && "${ACTION}" != "destroy" ]]; then
  echo "❌ statement/ddl y dml sin YAML"
  exit 1
fi

if [[ ! -d "${SECURITY_DIR}" && "${ACTION}" != "destroy" ]]; then
  echo "❌ no existe ${SECURITY_DIR}"
  exit 1
fi

echo "OK statements ddl=${DDL_N} dml=${DML_N} security_dir=${SECURITY_DIR}"
