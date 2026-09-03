#!/bin/bash
set -euo pipefail

# Ejecuta el merge y captura cuerpo y código HTTP
RESPONSE_FILE="merge_response.json"
HTTP_CODE=$(
curl -sS -X PUT \
    -H "Authorization: token ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${OWNER_REPO}/pulls/${NUM_PR}/merge" \
    -d '{"merge_method":"merge"}' \
    -w "%{http_code}" \
    -o "${RESPONSE_FILE}"
)

echo "HTTP_CODE=${HTTP_CODE}"
echo "BODY:"
cat "${RESPONSE_FILE}" || true
echo

# Si el servidor respondió con cuerpo vacío, evita jq error
if [[ ! -s "${RESPONSE_FILE}" ]]; then
echo "❌ Respuesta vacía del endpoint de merge." >&2
echo "merge_status=empty_response" >> $GITHUB_OUTPUT
echo "http_code=${HTTP_CODE}" >> $GITHUB_OUTPUT
exit 1
fi

# Extrae campos relevantes del JSON
MERGED=$(jq -r '.merged // empty' < "${RESPONSE_FILE}")
MESSAGE=$(jq -r '.message // empty' < "${RESPONSE_FILE}")
SHA=$(jq -r '.sha // empty' < "${RESPONSE_FILE}")

echo "merged=${MERGED}"
echo "message=${MESSAGE}"
echo "sha=${SHA}"

# Publica outputs para otros pasos
echo "http_code=${HTTP_CODE}" >> $GITHUB_OUTPUT
echo "merged=${MERGED}" >> $GITHUB_OUTPUT
echo "message=${MESSAGE}" >> $GITHUB_OUTPUT
echo "sha=${SHA}" >> $GITHUB_OUTPUT

# Validación por código HTTP + campo merged
# Éxito típico: HTTP 200 y "merged": true
if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "201" ]]; then
if [[ "${MERGED}" == "true" ]]; then
    echo "✅ Merge realizado correctamente. Commit merge: ${SHA}"
    exit 0
else
    echo "❌ HTTP ${HTTP_CODE} pero merged=false. Mensaje: ${MESSAGE}" >&2
    exit 1
fi
else
    echo "❌ HTTP ${HTTP_CODE} - ${MESSAGE}" >&2
    exit 1
fi




