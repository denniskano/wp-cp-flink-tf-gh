#!/usr/bin/env bash
# Baja la CA mTLS (PEM) de Vault a <out_dir>/<namespace>.pem.
# No imprime el PEM. Sin accepted_client_ca_vault en el YAML, no-op.
# Uso: fetch-temporal-ca-vault.sh <namespaces_dir> <out_dir>
# VAULT_ADDR y VAULT_TOKEN solo si algún YAML trae accepted_client_ca_vault.
set -euo pipefail
set +x

NS_DIR="${1:?namespaces_dir}"
OUT_DIR="${2:?out_dir}"

ok() { echo "OK  $*"; }
fail() { echo "❌ $*" >&2; exit 1; }

command -v yq >/dev/null || fail "yq es requerido"
mkdir -p "${OUT_DIR}"
shopt -s nullglob
NS_FILES=("${NS_DIR}"/*.yaml)

need_vault=0
for yf in "${NS_FILES[@]}"; do
  path="$(yq -r '.accepted_client_ca_vault.path // ""' "${yf}")"
  [[ -n "${path}" && "${path}" != "null" ]] && need_vault=1
done
if [[ "${need_vault}" -eq 0 ]]; then
  echo "sin accepted_client_ca_vault; nada que bajar"
  exit 0
fi

command -v vault >/dev/null || fail "vault CLI requerido"
[[ -n "${VAULT_ADDR:-}" && -n "${VAULT_TOKEN:-}" ]] || fail "VAULT_ADDR y VAULT_TOKEN requeridos para bajar CA mTLS"
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

n=0
for yf in "${NS_FILES[@]}"; do
  name="$(yq -r '.name // ""' "${yf}")"
  [[ -n "${name}" && "${name}" != "null" ]] || continue
  path="$(yq -r '.accepted_client_ca_vault.path // ""' "${yf}")"
  [[ -n "${path}" && "${path}" != "null" ]] || continue
  field="$(yq -r '.accepted_client_ca_vault.field // "pem"' "${yf}")"
  [[ -n "${field}" && "${field}" != "null" ]] || field="pem"
  mount="$(yq -r '.accepted_client_ca_vault.mount // "peve/kv2"' "${yf}")"
  [[ -n "${mount}" && "${mount}" != "null" ]] || mount="peve/kv2"

  pem="$(vault kv get -mount="${mount}" -field="${field}" "${path}")" || fail "Vault: no se leyó ${mount}/${path} field=${field} (${name})"
  [[ -n "${pem}" ]] || fail "Vault: campo ${field} vacío en ${path} (${name})"
  umask 077
  printf '%s\n' "${pem}" >"${OUT_DIR}/${name}.pem"
  n=$((n + 1))
  ok "ca ${name} ← ${mount}/${path}#${field}"
done

if [[ "${n}" -eq 0 ]]; then
  echo "sin accepted_client_ca_vault; nada que bajar"
fi
