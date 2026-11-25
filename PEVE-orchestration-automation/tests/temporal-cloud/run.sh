#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VALIDATE="${ROOT}/scripts/ci/validate-temporal-yaml.sh"
HERE="$(cd "$(dirname "$0")" && pwd)"
FIX="${HERE}/fixtures/PEVE"
YAML_REPO="$(cd "${ROOT}/../PEVE-orchestration-resources" && pwd)"

ok() { echo "OK  $*"; }
fail() { echo "FAIL $*"; exit 1; }

echo "== YAML PEVE/dev (resources): debe pasar =="
"${VALIDATE}" PEVE dev "${YAML_REPO}/PEVE/dev" plan || fail "PEVE/dev"
ok "PEVE/dev"

echo "== YAML PEVE/cert: debe pasar =="
"${VALIDATE}" PEVE cert "${YAML_REPO}/PEVE/cert" plan || fail "PEVE/cert"
ok "PEVE/cert"

echo "== YAML PEVE/prod (par HA centralus+use1): debe pasar =="
"${VALIDATE}" PEVE prod "${YAML_REPO}/PEVE/prod" plan || fail "PEVE/prod"
ok "PEVE/prod"

echo "== prod 1 región: debe fallar =="
if "${VALIDATE}" PEVE prod "${FIX}/prod-one-region" plan; then
  fail "prod con 1 región debió fallar"
fi
ok "prod 1 región bloqueado"

echo "== prod par HA inválido (azure-centralus + azure-australiaeast): debe fallar =="
if "${VALIDATE}" PEVE prod "${FIX}/prod-bad-ha" plan; then
  fail "par Azure–Azure debió fallar"
fi
ok "par HA inválido bloqueado"

echo "== name que no calza CODAPP: debe fallar =="
if "${VALIDATE}" PEVE dev "${FIX}/bad-name" plan; then
  fail "name ajeno a peve- debió fallar"
fi
ok "name CODAPP bloqueado"

echo "== labels con mayúsculas: debe fallar =="
if "${VALIDATE}" PEVE dev "${FIX}/bad-tags" plan; then
  fail "label PEVE debió fallar"
fi
ok "labels mayúsculas bloqueadas"

echo "== type private sin PE id: debe fallar =="
if "${VALIDATE}" PEVE dev "${FIX}/private-no-id" plan; then
  fail "private sin azure_pe_resource_id debió fallar"
fi
ok "private sin PE id bloqueado"

echo "== mTLS con path de Vault: debe pasar =="
"${VALIDATE}" PEVE dev "${FIX}/mtls-ok" plan || fail "mtls-ok"
ok "mTLS + Vault path"

echo "== api_key_auth=false sin CA: debe fallar =="
if "${VALIDATE}" PEVE dev "${FIX}/mtls-no-ca" plan; then
  fail "mTLS sin CA debió fallar"
fi
ok "mTLS sin CA bloqueado"

echo "tests/temporal-cloud: OK"
