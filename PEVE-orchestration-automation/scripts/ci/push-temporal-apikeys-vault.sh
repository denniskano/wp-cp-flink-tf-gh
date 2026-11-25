#!/usr/bin/env bash
# Sube tokens de temporalcloud_apikey a Vault. No imprime valores.
# Uso: push-temporal-apikeys-vault.sh <codapp> <env> <tf_workdir>
# Requiere VAULT_ADDR y VAULT_TOKEN.
set -euo pipefail
set +x

CODAPP="${1:?CODAPP}"
ENV="${2:?dev|cert|prod}"
TFDIR="${3:?tf_workdir}"

CODAPP_LO="$(printf '%s' "${CODAPP}" | tr '[:upper:]' '[:lower:]')"
export VAULT_SKIP_VERIFY="${VAULT_SKIP_VERIFY:-true}"

command -v vault >/dev/null || { echo "vault CLI requerido" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq requerido" >&2; exit 1; }
[[ -n "${VAULT_ADDR:-}" && -n "${VAULT_TOKEN:-}" ]] || { echo "VAULT_ADDR y VAULT_TOKEN requeridos" >&2; exit 1; }

cd "${TFDIR}"
raw="$(terraform output -json apikey_tokens)" || { echo "terraform output apikey_tokens falló" >&2; exit 1; }
n="$(printf '%s' "${raw}" | jq 'length')"
if [[ "${n}" -eq 0 ]]; then
  echo "sin apikey_tokens; nada que subir"
  exit 0
fi

while IFS=$'\t' read -r name token; do
  [[ -n "${name}" ]] || { echo "apikey_tokens: display_name vacío" >&2; exit 1; }
  [[ -n "${token}" && "${token}" != "null" ]] || { echo "apikey_tokens: token vacío para ${name}" >&2; exit 1; }
  vault kv put -mount=peve/kv2 \
    "${ENV}/${CODAPP_LO}/temporal/apikeys/${name}" \
    token="${token}" >/dev/null
  echo "OK vault apikey ${name}"
done < <(printf '%s' "${raw}" | jq -r 'to_entries[] | [.key, .value] | @tsv')
