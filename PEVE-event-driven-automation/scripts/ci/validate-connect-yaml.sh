#!/usr/bin/env bash
# Solo Kafka Connect: existencia de connects/ + security/ (sin Confluent).
# plan/apply sin YAML: OK (Terraform destruirá los conectores del use-case).
# pause/resume: hace falta connects/ con YAML.
# Uso: validate-connect-yaml.sh <connectors_dir> <security_dir> <action>
set -euo pipefail

CONNECTORS_DIR="${1:?connectors_dir}"
SECURITY_DIR="${2:?security_dir}"
ACTION="${3:-plan}"

YAML_COUNT=0
if [[ -d "${CONNECTORS_DIR}" ]]; then
  YAML_COUNT="$(find "${CONNECTORS_DIR}" -maxdepth 1 -type f -name '*.yaml' | wc -l | tr -d ' ')"
fi

if [[ "${ACTION}" == "pause" || "${ACTION}" == "resume" ]]; then
  if [[ ! -d "${CONNECTORS_DIR}" || "${YAML_COUNT}" -eq 0 ]]; then
    echo "❌ pause/resume requiere ${CONNECTORS_DIR} con YAML"
    exit 1
  fi
fi

if [[ "${YAML_COUNT}" -eq 0 ]]; then
  echo "⚠️  connects/ ausente o vacío; plan/apply destruirá los conectores de este use-case."
  echo "OK connects=0 security_dir=${SECURITY_DIR}"
  exit 0
fi

if [[ ! -d "${SECURITY_DIR}" ]]; then
  echo "❌ no existe ${SECURITY_DIR} (hace falta security/ si hay conectores)"
  exit 1
fi

echo "OK connects=${YAML_COUNT} security_dir=${SECURITY_DIR}"
