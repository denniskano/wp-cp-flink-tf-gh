#!/usr/bin/env bash
# Valida YAML Temporal Cloud: nombre, CODAPP, regiones, par HA (prod=2 y par válido).
# Uso: validate-temporal-yaml.sh <codapp> <env> <app_root> [action]
#   env = dev|cert|prod
#   app_root = .../{CODAPP}/{env}
set -euo pipefail

CODAPP="${1:?CODAPP}"
ENV="${2:?dev|cert|prod}"
APP_ROOT="${3:?app_root}"
ACTION="${4:-plan}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAIRS_FILE="${SCRIPT_DIR}/temporal-ha-pairs.json"

ok() { echo "OK  $*"; }
fail() { echo "❌ $*" >&2; exit 1; }

CODAPP_UP="$(printf '%s' "${CODAPP}" | tr '[:lower:]' '[:upper:]')"
CODAPP_LO="$(printf '%s' "${CODAPP}" | tr '[:upper:]' '[:lower:]')"
if [[ ! "${CODAPP_UP}" =~ ^[A-Z0-9]{4}(-PARTNER)?$ ]]; then
  fail "CODAPP debe ser 4 letras/dígitos (opcional -PARTNER): ${CODAPP}"
fi
case "${ENV}" in
  dev|cert|prod) ;;
  *) fail "env debe ser dev, cert o prod (no desa)" ;;
esac

NS_DIR="${APP_ROOT}/namespaces"
if [[ ! -d "${NS_DIR}" ]]; then
  if [[ "${ACTION}" == "destroy" ]]; then
    echo "namespaces/ ausente; destroy continúa."
    exit 0
  fi
  fail "no existe ${NS_DIR}"
fi

shopt -s nullglob
NS_FILES=("${NS_DIR}"/*.yaml)
if [[ ${#NS_FILES[@]} -eq 0 ]]; then
  if [[ "${ACTION}" == "destroy" ]]; then
    echo "namespaces/ sin YAML; destroy continúa."
    exit 0
  fi
  fail "namespaces/ sin YAML"
fi

command -v yq >/dev/null || fail "yq es requerido"
command -v jq >/dev/null || fail "jq es requerido"
[[ -f "${PAIRS_FILE}" ]] || fail "falta ${PAIRS_FILE}"

ha_ok() {
  local a="$1" b="$2"
  jq -e --arg a "$a" --arg b "$b" '
    (.[$a] // []) | index($b) != null
  ' "${PAIRS_FILE}" >/dev/null
}

NAMES=()
CONN_NAMES=()
SA_NAMES=()
KEY_NAMES=()

for yf in "${NS_FILES[@]}"; do
  name="$(yq -r '.name // ""' "${yf}")"
  [[ -n "${name}" && "${name}" != "null" ]] || fail "name vacío: ${yf}"
  if [[ ! "${name}" =~ ^[a-z][a-z0-9-]{0,62}[a-z0-9]$ ]]; then
    fail "name inválido (2-64, [a-z0-9-], empieza letra, no termina -): ${name} en ${yf}"
  fi
  if [[ ! "${name}" =~ ^${CODAPP_LO}-(dev|cert|prod)(-[a-z0-9]+)*$ ]]; then
    fail "name debe ser ${CODAPP_LO}-{dev|cert|prod}[-suffix]: ${name} en ${yf}"
  fi
  env_in_name="$(printf '%s' "${name}" | cut -d- -f2)"
  [[ "${env_in_name}" == "${ENV}" ]] || fail "name ${name} no coincide con env=${ENV} (${yf})"

  for existing in "${NAMES[@]+"${NAMES[@]}"}"; do
    [[ "${existing}" != "${name}" ]] || fail "name duplicado: ${name}"
  done
  NAMES+=("${name}")

  auth="$(yq -r '.api_key_auth // true' "${yf}")"
  [[ "${auth}" == "true" ]] || fail "solo api_key_auth=true (${yf})"

  retention="$(yq -r '.retention_days // 14' "${yf}")"
  if [[ ! "${retention}" =~ ^[0-9]+$ ]] || [[ "${retention}" -lt 1 ]]; then
    fail "retention_days inválido en ${yf}"
  fi

  # labels y tags son el mismo mapa Temporal (máx. 10; a-z 0-9 . _ - @). tags pisa labels.
  merged_tags="$(yq -o=json '(.labels // {}) * (.tags // {})' "${yf}")"
  ntags="$(printf '%s' "${merged_tags}" | jq 'length')"
  if [[ "${ntags}" -gt 10 ]]; then
    fail "${name}: máximo 10 tags/labels (got ${ntags})"
  fi
  while IFS=$'\t' read -r tk tv ttype; do
    [[ -n "${tk}" ]] || continue
    [[ "${ttype}" == "string" ]] || fail "${name}: tag/label ${tk} debe ser string (got ${ttype})"
    if [[ ! "${tk}" =~ ^[a-z0-9._@-]{1,63}$ ]]; then
      fail "${name}: tag/label key inválida '${tk}' (1-63, solo a-z 0-9 . _ - @)"
    fi
    if [[ ! "${tv}" =~ ^[a-z0-9._@-]{1,63}$ ]]; then
      fail "${name}: tag/label ${tk}='${tv}' inválido (1-63, solo a-z 0-9 . _ - @; Temporal no admite mayúsculas)"
    fi
  done < <(printf '%s' "${merged_tags}" | jq -r 'to_entries[] | [.key, (.value|tostring), (.value|type)] | @tsv')

  regions=()
  while IFS= read -r r; do
    [[ -n "${r}" ]] && regions+=("${r}")
  done < <(yq -r '.regions[]?' "${yf}")
  nreg="${#regions[@]}"
  if [[ "${nreg}" -lt 1 || "${nreg}" -gt 2 ]]; then
    fail "${name}: regions debe tener 1 o 2 códigos (got ${nreg})"
  fi
  for r in "${regions[@]}"; do
    jq -e --arg r "$r" 'has($r)' "${PAIRS_FILE}" >/dev/null \
      || fail "${name}: región desconocida o no listada en HA matrix: ${r}"
  done
  if [[ "${ENV}" == "prod" && "${nreg}" -ne 2 ]]; then
    fail "${name}: prod exige 2 regiones (HA). Ver docs/TEMPORAL-HA.md"
  fi
  if [[ "${nreg}" -eq 2 ]]; then
    ha_ok "${regions[0]}" "${regions[1]}" \
      || fail "${name}: ${regions[0]} + ${regions[1]} no es par HA de Temporal. Ver docs/TEMPORAL-HA.md (Azure-centralus no tiene réplica Azure–Azure)"
  fi

  conn_n="$(yq -r '.connectivity | length // 0' "${yf}")"
  for ((i = 0; i < conn_n; i++)); do
    cname="$(yq -r ".connectivity[$i].name // \"\"" "${yf}")"
    ctype="$(yq -r ".connectivity[$i].type // \"\"" "${yf}")"
    creg="$(yq -r ".connectivity[$i].region // \"\"" "${yf}")"
    [[ -n "${cname}" ]] || fail "connectivity.name vacío en ${yf}"
    for existing in "${CONN_NAMES[@]+"${CONN_NAMES[@]}"}"; do
      [[ "${existing}" != "${cname}" ]] || fail "connectivity.name duplicado: ${cname}"
    done
    CONN_NAMES+=("${cname}")
    case "${ctype}" in
      public|private) ;;
      *) fail "connectivity.type debe ser public|private (${yf} ${cname})" ;;
    esac
    if [[ "${ctype}" == "private" ]]; then
      [[ -n "${creg}" && "${creg}" != "null" ]] || fail "${cname}: private requiere region"
      found=0
      for r in "${regions[@]}"; do
        [[ "${r}" == "${creg}" ]] && found=1
      done
      [[ "${found}" -eq 1 ]] || fail "${cname}: region ${creg} no está en regions del namespace"
      if [[ "${creg}" == azure-* ]]; then
        pe="$(yq -r ".connectivity[$i].azure_pe_resource_id // \"\"" "${yf}")"
        [[ -n "${pe}" && "${pe}" != "null" ]] || fail "${cname}: Azure private requiere azure_pe_resource_id (PE lo crea Cloud Governance)"
      elif [[ "${creg}" == gcp-* ]]; then
        cid="$(yq -r ".connectivity[$i].connection_id // \"\"" "${yf}")"
        gp="$(yq -r ".connectivity[$i].gcp_project_id // \"\"" "${yf}")"
        [[ -n "${cid}" && -n "${gp}" ]] || fail "${cname}: GCP private requiere connection_id y gcp_project_id"
      else
        cid="$(yq -r ".connectivity[$i].connection_id // \"\"" "${yf}")"
        [[ -n "${cid}" && "${cid}" != "null" ]] || fail "${cname}: AWS private requiere connection_id (vpce-…)"
      fi
    fi
  done

  sa_n="$(yq -r '.service_accounts | length // 0' "${yf}")"
  for ((i = 0; i < sa_n; i++)); do
    san="$(yq -r ".service_accounts[$i].name // \"\"" "${yf}")"
    perm="$(yq -r ".service_accounts[$i].permission // \"write\"" "${yf}")"
    [[ -n "${san}" ]] || fail "service_accounts.name vacío en ${yf}"
    for existing in "${SA_NAMES[@]+"${SA_NAMES[@]}"}"; do
      [[ "${existing}" != "${san}" ]] || fail "service_account duplicado: ${san}"
    done
    SA_NAMES+=("${san}")
    case "${perm}" in
      admin|write|read) ;;
      *) fail "permission debe ser admin|write|read (${san})" ;;
    esac
    kn="$(yq -r ".service_accounts[$i].api_keys | length // 0" "${yf}")"
    for ((j = 0; j < kn; j++)); do
      knm="$(yq -r ".service_accounts[$i].api_keys[$j].display_name // \"\"" "${yf}")"
      exp="$(yq -r ".service_accounts[$i].api_keys[$j].expiry_time // \"\"" "${yf}")"
      [[ -n "${knm}" ]] || fail "api_keys.display_name vacío (${san})"
      [[ -n "${exp}" ]] || fail "api_keys.expiry_time RFC3339 requerido (${knm})"
      for existing in "${KEY_NAMES[@]+"${KEY_NAMES[@]}"}"; do
        [[ "${existing}" != "${knm}" ]] || fail "api key duplicada: ${knm}"
      done
      KEY_NAMES+=("${knm}")
    done
  done

  sa_attr_n="$(yq -r '.search_attributes | length // 0' "${yf}")"
  for ((i = 0; i < sa_attr_n; i++)); do
    st="$(yq -r ".search_attributes[$i].type // \"\"" "${yf}" | tr '[:upper:]' '[:lower:]')"
    case "${st}" in
      bool|datetime|double|int|keyword|keyword_list|text) ;;
      *) fail "search_attributes.type inválido en ${yf}: ${st}" ;;
    esac
  done
done

NEXUS_DIR="${APP_ROOT}/nexus"
if [[ -d "${NEXUS_DIR}" ]]; then
  for yf in "${NEXUS_DIR}"/*.yaml; do
    [[ -f "${yf}" ]] || continue
    nname="$(yq -r '.name // ""' "${yf}")"
    tns="$(yq -r '.target_namespace // ""' "${yf}")"
    tq="$(yq -r '.task_queue // ""' "${yf}")"
    [[ -n "${nname}" && -n "${tns}" && -n "${tq}" ]] || fail "nexus requiere name, target_namespace, task_queue: ${yf}"
    found=0
    for n in "${NAMES[@]}"; do
      [[ "${n}" == "${tns}" ]] && found=1
    done
    [[ "${found}" -eq 1 ]] || fail "nexus ${nname}: target_namespace ${tns} no está en este env"
    callers=()
    while IFS= read -r c; do
      [[ -n "${c}" ]] && callers+=("${c}")
    done < <(yq -r '.allowed_callers[]?' "${yf}")
    [[ ${#callers[@]} -ge 1 ]] || fail "nexus ${nname}: allowed_callers vacío"
    for c in "${callers[@]}"; do
      found=0
      for n in "${NAMES[@]}"; do
        [[ "${n}" == "${c}" ]] && found=1
      done
      [[ "${found}" -eq 1 ]] || fail "nexus ${nname}: caller ${c} no está en este env"
    done
  done
fi

echo "OK temporal yaml ns=${#NS_FILES[@]} env=${ENV} dir=${NS_DIR}"
