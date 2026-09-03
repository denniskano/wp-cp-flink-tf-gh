#!/usr/bin/env bash
# Arma JSON flink_credentials ({"SA/AK": {key, secret, sa}}) desde KEY_* / SECRET_* en el entorno.
# Uso: collect-flink-vault-paths.sh … | build-flink-credentials.sh
# Cada línea de stdin es una ruta vault-action; se usa el tramo posterior a /ccloud/.
set -euo pipefail

if [[ -t 0 ]]; then
  echo "{}"
  exit 0
fi

json="$(
  awk '{print $1}' \
  | sed 's#.*/ccloud/##' \
  | sort -u \
  | while IFS=/ read -r sa ak; do
      [[ -z "${sa:-}" || -z "${ak:-}" ]] && continue
      key_var="KEY_${ak}"
      sec_var="SECRET_${ak}"
      key_val="${!key_var:-}"
      sec_val="${!sec_var:-}"
      if [[ -z "${key_val}" || -z "${sec_val}" ]]; then
        echo "❌ faltan secretos para ${sa}/${ak}" >&2
        exit 1
      fi
      jq -cn --arg k "${sa}/${ak}" --arg key "${key_val}" --arg secret "${sec_val}" --arg sa "${sa}" \
        '{($k): {key:$key, secret:$secret, sa:$sa}}'
    done \
  | jq -cs 'add // {}'
)"

printf '%s\n' "${json}"
