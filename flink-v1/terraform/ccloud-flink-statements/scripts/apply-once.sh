#!/usr/bin/env bash
# Crea un Flink statement (apply: once). Terraform solo lo llama en create del marcador.
set -euo pipefail

ACTION="${ONCE_ACTION:?ONCE_ACTION}"
NAME="${ONCE_NAME:?ONCE_NAME}"
REST="${ONCE_REST_ENDPOINT:?ONCE_REST_ENDPOINT}"
ORG="${ONCE_ORG_ID:?ONCE_ORG_ID}"
ENV="${ONCE_ENV_ID:?ONCE_ENV_ID}"
KEY="${CONFLUENT_FLINK_API_KEY:?CONFLUENT_FLINK_API_KEY}"
SECRET="${CONFLUENT_FLINK_API_SECRET:?CONFLUENT_FLINK_API_SECRET}"

REST="${REST%/}"
URL="${REST}/sql/v1/organizations/${ORG}/environments/${ENV}/statements"
AUTH="$(printf '%s' "${KEY}:${SECRET}" | base64 | tr -d '\n')"
BODY_FILE="$(mktemp)"
trap 'rm -f "${BODY_FILE}"' EXIT

if [[ "${ACTION}" == "delete" ]]; then
  code="$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X DELETE \
    -H "Authorization: Basic ${AUTH}" \
    "${URL}/${NAME}")"
  if [[ "${code}" == "200" || "${code}" == "202" || "${code}" == "204" || "${code}" == "404" ]]; then
    echo "once delete ${NAME}: HTTP ${code}"
    exit 0
  fi
  echo "❌ once delete ${NAME}: HTTP ${code}" >&2
  cat "${BODY_FILE}" >&2 || true
  exit 1
fi

if [[ "${ACTION}" != "create" ]]; then
  echo "❌ ONCE_ACTION debe ser create o delete" >&2
  exit 1
fi

: "${ONCE_SQL:?ONCE_SQL}"
: "${ONCE_POOL_ID:?ONCE_POOL_ID}"
: "${ONCE_PRINCIPAL:?ONCE_PRINCIPAL}"
STOPPED="$(printf '%s' "${ONCE_STOPPED:-false}" | tr '[:upper:]' '[:lower:]')"
[[ "${STOPPED}" == "true" ]] && STOPPED_JSON=true || STOPPED_JSON=false

export STOPPED_JSON
export ONCE_PROPERTIES="${ONCE_PROPERTIES:-{}}"
BODY="$(python3 -c '
import json, os
props = json.loads(os.environ.get("ONCE_PROPERTIES") or "{}")
spec = {
  "statement": os.environ["ONCE_SQL"],
  "compute_pool_id": os.environ["ONCE_POOL_ID"],
  "principal": os.environ["ONCE_PRINCIPAL"],
  "stopped": os.environ["STOPPED_JSON"] == "true",
}
if props:
  spec["properties"] = props
print(json.dumps({"name": os.environ["ONCE_NAME"], "spec": spec}))
')"

code="$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X POST \
  -H "Authorization: Basic ${AUTH}" \
  -H "content-type: application/json" \
  -d "${BODY}" \
  "${URL}")"

if [[ "${code}" == "409" ]]; then
  echo "once create ${NAME}: ya existe (409), no se re-ejecuta"
  exit 0
fi

if [[ "${code}" != "200" && "${code}" != "201" && "${code}" != "202" ]]; then
  echo "❌ once create ${NAME}: HTTP ${code}" >&2
  cat "${BODY_FILE}" >&2 || true
  exit 1
fi

echo "once create ${NAME}: HTTP ${code}, esperando fase..."
for _ in $(seq 1 60); do
  get_code="$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    -H "Authorization: Basic ${AUTH}" \
    "${URL}/${NAME}")"
  if [[ "${get_code}" != "200" ]]; then
    echo "  GET HTTP ${get_code}, reintento..."
    sleep 5
    continue
  fi
  phase="$(python3 -c 'import json
try:
  d=json.load(open("'"${BODY_FILE}"'"))
  print((d.get("status") or {}).get("phase") or "")
except Exception:
  print("")
')"
  echo "  phase=${phase:-?}"
  case "${phase}" in
    COMPLETED|RUNNING|STOPPED) echo "once create ${NAME}: ${phase}"; exit 0 ;;
    FAILED)
      echo "❌ once create ${NAME}: FAILED" >&2
      cat "${BODY_FILE}" >&2 || true
      exit 1
      ;;
  esac
  sleep 5
done

echo "❌ once create ${NAME}: timeout esperando COMPLETED/RUNNING" >&2
exit 1
