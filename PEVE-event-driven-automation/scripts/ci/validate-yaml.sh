#!/usr/bin/env bash
# Valida YAML de connects/ (extensión .yaml, no vacío si ACTION != destroy).
# Uso: validate-yaml.sh <connectors_dir> <security_dir> <action>
set -euo pipefail

CONNECTORS_DIR="${1:?connectors_dir}"
SECURITY_DIR="${2:?security_dir}"
ACTION="${3:-plan}"

if [[ ! -d "${CONNECTORS_DIR}" ]]; then
  if [[ "${ACTION}" == "destroy" ]]; then
    echo "connects/ ausente; destroy continúa."
    exit 0
  fi
  echo "❌ no existe ${CONNECTORS_DIR}"
  exit 1
fi

YAML_COUNT="$(find "${CONNECTORS_DIR}" -maxdepth 1 -type f -name '*.yaml' | wc -l | tr -d ' ')"
if [[ "${YAML_COUNT}" -eq 0 && "${ACTION}" != "destroy" ]]; then
  echo "❌ connects/ sin YAML"
  exit 1
fi

if [[ ! -d "${SECURITY_DIR}" && "${ACTION}" != "destroy" ]]; then
  echo "❌ no existe ${SECURITY_DIR}"
  exit 1
fi

echo "OK connects=${YAML_COUNT} security_dir=${SECURITY_DIR}"
