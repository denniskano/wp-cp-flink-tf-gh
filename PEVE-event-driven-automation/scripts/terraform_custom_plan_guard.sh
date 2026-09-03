#!/bin/bash

# tf_plan_guard.sh
# Valida que el plan de Terraform solo tenga Add/Modify y NO Delete/Destroy (incluye Replace opcional).
# Ahora soporta pasar terraform -chdir=<ruta> como parámetro.
#
# Uso:
#   source tf_plan_guard.sh
#   terraform_custom_plan [-w WORK_DIR] [--chdir=RUTA] [-o PLAN_OUT] [-j PLAN_JSON] [--strict-replace|--allow-replace]
#
#   Opciones:
#     -w, --workdir DIR     Cambia de directorio con cd antes de ejecutar (si NO se usa --chdir).
#     --chdir=DIR           Usa terraform -chdir=DIR en cada comando (tiene prioridad sobre -w).
#     -o, --out FILE        Archivo binario del plan (default: tfplan.bin).
#     -j, --json FILE       Archivo JSON del plan (default: tfplan.json).
#     --strict-replace      Bloquea reemplazos (delete+create). [default]
#     --allow-replace       Permite reemplazos (delete+create).
#
# Códigos:
#   0 = OK (Add/Modify/No changes)
#   1 = Plan inválido (Delete/Destroy o Replace si strict)
#   2 = Error operativo (Terraform/jq faltantes, plan inválido, etc.)

set -euo pipefail

terraform_custom_plan() {

  # --- Defaults ---
  local WORK_DIR="."
  local USE_CHDIR=""         # si se pasa --chdir=<ruta>, se guarda aquí
  local PLAN_OUT="tfplan.bin"
  local PLAN_JSON="tfplan.json"
  local STRICT_REPLACE=1     # 1 = bloquear replace; 0 = permitir replace

  # --- Parseo simple de args ---
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--workdir)
        WORK_DIR="${2:-.}"; shift 2 ;;
      --chdir=*)
        USE_CHDIR="${1#--chdir=}"; shift 1 ;;
      -o|--out)
        PLAN_OUT="${2:-tfplan.bin}"; shift 2 ;;
      -j|--json)
        PLAN_JSON="${2:-tfplan.json}"; shift 2 ;;
      --strict-replace)
        STRICT_REPLACE=1; shift ;;
      --allow-replace)
        STRICT_REPLACE=0; shift ;;
      -h|--help)
#        echo "Uso: terraform_custom_plan [-w DIR] [--chdir=DIR] [-o FILE] [-j FILE]"
        echo "Uso: terraform_custom_plan [-w DIR] [--chdir=DIR] [-o FILE] [-j FILE] [--strict-replace|--allow-replace]"
        return 2 ;;
      *)
        echo "Argumento no reconocido: $1"; return 2 ;;
    esac
  done

  # --- Validaciones de entorno ---
  if ! command -v jq >/dev/null 2>&1; then
    echo "❌ jq no está instalado o no está en PATH."
    return 2
  fi

  # --- Construir prefijo terraform con -chdir si aplica ---
  local TF_PREFIX="terraform"
  if [[ -n "${USE_CHDIR}" ]]; then
    TF_PREFIX="terraform -chdir=${USE_CHDIR}"
    echo "📂 Usando terraform -chdir=${USE_CHDIR}"
  fi

  # --- Cambiar de directorio local si NO se usa --chdir ---
  local PREV_DIR
  PREV_DIR="$(pwd)"
  if [[ -z "${USE_CHDIR}" ]]; then
    echo "📂 Cambiando directorio (cd) a '${WORK_DIR}'..."
    cd "${WORK_DIR}"
  fi

  echo "🧭 Generando plan..."
  # Guardamos el output textual para mostrar resumen si aparece
  ${TF_PREFIX} plan -lock-timeout=10m -input=false -out "${PLAN_OUT}" -no-color| tee plan_output.txt

  local SUMMARY_TEXT
  SUMMARY_TEXT="$(tail -n 80 plan_output.txt | tr -d '\r')"

  # --- JSON ---
  echo "📄 Exportando plan a JSON..."
  ${TF_PREFIX} show -json "${PLAN_OUT}" > "${PLAN_JSON}"

  # --- Cálculos con jq ---
  local HAS_ACTIONS COUNT_ADD COUNT_CHANGE COUNT_DELETE HAS_REPLACE HAS_DELETE_OR_DESTROY

  HAS_ACTIONS="$(
    jq '.resource_changes | length' "${PLAN_JSON}"
  )"

  COUNT_ADD="$(
    jq -r '
      [.resource_changes[]?.change.actions] // []
      | [ .[] | select(index("create")) ] | length
    ' "${PLAN_JSON}"
  )"

  COUNT_CHANGE="$(
    jq -r '
      [.resource_changes[]?.change.actions] // []
      | [ .[] | select(index("update")) ] | length
    ' "${PLAN_JSON}"
  )"

  COUNT_DELETE="$(
    jq -r '
      [.resource_changes[]?.change.actions] // []
      | [ .[] | select(index("delete")) ] | length
    ' "${PLAN_JSON}"
  )"

  HAS_REPLACE="$(
    jq -r '
      [.resource_changes[]?.change.actions] // []
      | any(. != null and (index("delete") != null and index("create") != null))
    ' "${PLAN_JSON}"
  )"

  HAS_DELETE_OR_DESTROY="$(
    jq -r '
      [.resource_changes[]?.change.actions] // []
      | any(. != null and any(.[]; . == "delete" or . == "destroy"))
    ' "${PLAN_JSON}"
  )"

#  echo "🔎 Resumen (JSON): add=${COUNT_ADD}, change=${COUNT_CHANGE}, delete=${COUNT_DELETE}" 2>&1 | tee -a /tmp/tf_output.txt

#operadores aritméticos bash:
# -eq  → igual
# -gt  → mayor que
# -lt  → menor que

  MSG_ADD="recurso será creado"
  MSG_CHANGE="recurso será modificado"
  MSG_DELETE="recurso será eliminado"
  [[ $COUNT_ADD -gt 1 ]] && MSG_ADD="recursos serán creados"
  [[ $COUNT_CHANGE -gt 1 ]] && MSG_CHANGE="recursos serán modificados"
  [[ $COUNT_DELETE -gt 1 ]] && MSG_DELETE="recursos serán eliminados"

  echo "📝 Resumen del plan: $baseFilename" 2>&1 | tee -a /tmp/tf_output.txt
  echo "    ✔️ ${COUNT_ADD} ${MSG_ADD}" 2>&1 | tee -a /tmp/tf_output.txt
  echo "    🔄 ${COUNT_CHANGE} ${MSG_CHANGE} " 2>&1 | tee -a /tmp/tf_output.txt
  echo "    ❌ ${COUNT_DELETE} ${MSG_DELETE}" 2>&1 | tee -a /tmp/tf_output.txt

  # --- Decisiones ---
#  if [[ "${HAS_ACTIONS}" -eq 0 ]]; then
  if [[ $COUNT_ADD -eq 0 && $COUNT_CHANGE -eq 0 && $COUNT_DELETE -eq 0 ]]; then
    echo "✅ No changes. Your infrastructure matches the configuration." 2>&1 | tee -a /tmp/tf_output.txt
    #echo "✅ Plan válido (sin cambios)." 2>&1 | tee -a /tmp/tf_output.txt
    #if echo "${SUMMARY_TEXT}" | grep -q "No changes."; then
    #  echo "📝 Resumen textual: No changes. Your infrastructure matches the configuration."   2>&1 | tee -a /tmp/tf_output.txt
    #fi
    # Restaurar directorio si se usó cd
    if [[ -z "${USE_CHDIR}" ]]; then cd "${PREV_DIR}"; fi
    return 0
  fi

  if [[ "${STRICT_REPLACE}" -eq 1 && "${HAS_DELETE_OR_DESTROY}" == "true" ]]; then
    echo "❌ Plan inválido: se detectaron acciones de Delete/Destroy."   2>&1 | tee -a /tmp/tf_output.txt
    echo "    Política: solo Add/Modify permitidos." 2>&1 | tee -a /tmp/tf_output.txt
    if [[ -z "${USE_CHDIR}" ]]; then cd "${PREV_DIR}"; fi
    return 1
  fi

  if [[ "${STRICT_REPLACE}" -eq 0 && "${HAS_DELETE_OR_DESTROY}" == "true" ]]; then
    echo "⚠️ Aviso: reemplazos(Delete/Destroy) detectados y permitidos por --allow-replace." 2>&1 | tee -a /tmp/tf_output.txt
  fi

  STRICT_VALIDATE_ALLOW_ONLY_DELETE="${STRICT_VALIDATE_ALLOW_ONLY_DELETE:-false}"
  # Normaliza "null" o vacío a false
  [[ -z "$STRICT_VALIDATE_ALLOW_ONLY_DELETE" || "$STRICT_VALIDATE_ALLOW_ONLY_DELETE" == "null" ]] && STRICT_VALIDATE_ALLOW_ONLY_DELETE=false

  if [[ "${STRICT_REPLACE}" -eq 0 && "${STRICT_VALIDATE_ALLOW_ONLY_DELETE}" == "true" && $COUNT_ADD > 0 ]]; then
    echo "STRICT_VALIDATE_ALLOW_ONLY_DELETE $STRICT_VALIDATE_ALLOW_ONLY_DELETE"
    echo "❌ Aviso: solo Delete/Destroy estan permitidos ." 2>&1 | tee -a /tmp/tf_output.txt
    return 1
  fi

#  if [[ "${HAS_REPLACE}" == "true" && "${STRICT_REPLACE}" -eq 1 ]]; then
#    echo "❌ Plan inválido: se detectaron reemplazos (delete+create)."
#    echo "   Política: reemplazos bloqueados (--strict-replace). Usa --allow-replace para permitirlos."
#    if [[ -z "${USE_CHDIR}" ]]; then cd "${PREV_DIR}"; fi
#    return 1
#  fi

#  echo "✅ Plan válido: solo Add/Modify"
#  if [[ "${STRICT_REPLACE}" -eq 0 && "${HAS_REPLACE}" == "true" ]]; then
#    echo "⚠️ Aviso: reemplazos detectados y permitidos por --allow-replace."
#  fi

  # Mostrar resumen textual si está
  #if echo "${SUMMARY_TEXT}" | grep -qE '^Plan: [0-9]+ to add, [0-9]+ to change, [0-9]+ to destroy\.'; then
  #  echo "📝 Resumen textual: $(echo "${SUMMARY_TEXT}" | grep -E '^Plan: [0-9]+ to add, [0-9]+ to change, [0-9]+ to destroy\.')"   2>&1 | tee -a /tmp/tf_output.txt
  #fi


  if [[ -z "${USE_CHDIR}" ]]; then cd "${PREV_DIR}"; fi
  return 0
}

