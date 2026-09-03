#!/bin/bash
set -euo pipefail

# Ejecuta y captura cuerpo y código HTTP
RESPONSE_FILE="comments_response.json"
HTTP_CODE=$(
  curl -sS -X POST \
    -H "Authorization: token ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${OWNER_REPO}/issues/${NUM_PR}/comments" \
    -d "{
      \"body\": \"✅ Aprobación registrada por CI \nJira: ${JIRA_ISSUE} \nBuild: ${GITHUB_RUN_ID}\nCommit: ${GITHUB_SHA}\n🔗 Run: ${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}\"
    }" \
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
  echo "http_code=${HTTP_CODE}" >> $GITHUB_OUTPUT
  exit 1
fi

# Extrae campos relevantes del JSON
MESSAGE=$(jq -r '.message // empty' < "${RESPONSE_FILE}")
COMMIT_ID=$(jq -r '.commit_id // empty' < "${RESPONSE_FILE}")

# Publica outputs para otros pasos
echo "http_code=${HTTP_CODE}" >> $GITHUB_OUTPUT

# Validación por código HTTP
# Éxito típico: HTTP 200
if [[ "${HTTP_CODE}" == "200" || "${HTTP_CODE}" == "201" ]]; then
  echo "✅ Comments realizado correctamente. COMMIT_ID : ${COMMIT_ID}"
  exit 0
else
  echo "❌ HTTP ${HTTP_CODE} . Mensaje: ${MESSAGE}" >&2
  exit 1
fi

