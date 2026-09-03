#!/usr/bin/env bash
# Recorre statement/{ddl,dml}/*.yaml y emite líneas para hashicorp/vault-action.
# Uso: collect-flink-vault-paths.sh <path_hv_app> <ddl_dir> <dml_dir> <ENVIRONMENT>
# path_hv_app ejemplo desa: peve/kv2/data/dev/peve/ccloud/
set -euo pipefail

PATH_HV_APP="${1:?path_hv_app}"
DDL_DIR="${2:-}"
DML_DIR="${3:-}"
ENVIRONMENT="${4:-DES}"

regex_sa='^SA_AZC_(DES|CER|PRO)_([A-Za-z0-9]{4})_([A-Za-z0-9]{3}|[A-Za-z0-9]{8})_(0[1-9]|[1-9][0-9])$'
regex_ak='^AK_AZC_(DES|CER|PRO)_([A-Za-z0-9]{4})_FLINK_([A-Za-z0-9]{3}|[A-Za-z0-9]{8})_(0[1-9]|[1-9][0-9])$'

process_dir() {
  local dir="$1"
  local errors=0
  if [[ ! -d "${dir}" ]]; then
    return 0
  fi
  local n
  n="$(find "${dir}" -maxdepth 1 -type f -name '*.yaml' | wc -l | tr -d ' ')"
  if [[ "${n}" -eq 0 ]]; then
    return 0
  fi
  local stmt tmp sa ak env_lower path_final
  for stmt in "${dir}"/*.yaml; do
    tmp="${stmt}.with.environment"
    sed "s/\${environment}/${ENVIRONMENT}/g" "${stmt}" > "${tmp}"
    sa="$(yq -r '."service-account" // ""' "${tmp}")"
    ak="$(yq -r '."api-key" // ""' "${tmp}")"
    rm -f "${tmp}"
    if [[ -z "${sa}" || "${sa}" == "null" ]]; then
      echo "❌ sa vacío en ${stmt}" >&2
      errors=$((errors + 1))
      continue
    fi
    if [[ -z "${ak}" || "${ak}" == "null" ]]; then
      echo "❌ ak vacío en ${stmt}" >&2
      errors=$((errors + 1))
      continue
    fi
    if [[ ! "${sa}" =~ ${regex_sa} ]]; then
      echo "❌ sa NO cumple formato: ${sa}" >&2
      errors=$((errors + 1))
    fi
    if [[ ! "${ak}" =~ ${regex_ak} ]]; then
      echo "❌ ak NO cumple formato: ${ak}" >&2
      errors=$((errors + 1))
    fi
    env_lower="$(echo "${sa}" | cut -d'_' -f4 | tr '[:upper:]' '[:lower:]')"
    path_final="${PATH_HV_APP//peve/${env_lower}}"
    printf '%s%s/%s username | KEY_%s ;\n' "${path_final}" "${sa}" "${ak}" "${ak}"
    printf '%s%s/%s password | SECRET_%s ;\n' "${path_final}" "${sa}" "${ak}" "${ak}"
  done
  if [[ "${errors}" -gt 0 ]]; then
    echo "❌ Validación SA/AK falló con ${errors} error(es)." >&2
    exit 1
  fi
}

{
  process_dir "${DML_DIR}"
  process_dir "${DDL_DIR}"
} | sort -u
