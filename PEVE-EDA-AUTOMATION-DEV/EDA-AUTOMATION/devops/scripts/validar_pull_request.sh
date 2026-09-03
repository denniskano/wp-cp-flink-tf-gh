#!/bin/bash
set -euo pipefail

echo "Consultando PR #${NUM_PR} en ${OWNER_REPO}"
PR_JSON="pull_pr_response.json"
HTTP_CODE=$(curl -sS -H "Authorization: Bearer ${TOKEN}" \
                -H "Accept: application/vnd.github+json" \
                "https://api.github.com/repos/${OWNER_REPO}/pulls/${NUM_PR}" \
                -w "%{http_code}" \
                -o "${PR_JSON}" )

if [[ "${HTTP_CODE}" -lt 200 || "${HTTP_CODE}" -ge 300 ]]; then
  echo "❌ Error consultando PR (HTTP ${HTTP_CODE})"
  cat "${PR_JSON}"
  exit 1
fi

PR_STATE=$(grep -m1 '"state":' "${PR_JSON}" | sed -E 's/.*"state": *"([^"]+)".*/\1/')
PR_MERGED=$(grep -m1 '"merged":' "${PR_JSON}" | sed -E 's/.*"merged": *([^,]+).*/\1/')

if [[ "${PR_STATE}" == "closed" && "${PR_MERGED}" == "true" ]]; then
  echo "ℹ️ PR cerrado y mergeado"
  exit 1
elif [[ "${PR_STATE}" == "closed" ]]; then
  echo "ℹ️ PR cerrado (sin merge)"
  exit 1
fi

HEAD_SHA=$(cat "$PR_JSON" | jq -r '.head.sha')
if [[ -z "$HEAD_SHA" || "$HEAD_SHA" == "null" ]]; then
  echo "❌ No se pudo leer el PR. Revisa permisos del token y que el PR exista." >&2
  exit 1
fi

echo "PR head.sha: $HEAD_SHA"

# Valida si commit_id == head.sha
if [[ "${COMMIT_ID}" == "$HEAD_SHA" ]]; then
#  echo "belongs_to_pr=true" >> $GITHUB_OUTPUT
#  echo "is_head=true" >> $GITHUB_OUTPUT
  echo "✅ Commit [${COMMIT_ID}] indicado es el HEAD actual del PR."
else
  echo "❌ El commit [${COMMIT_ID}] indicado no es el HEAD actual del PR."
  exit 1
fi

