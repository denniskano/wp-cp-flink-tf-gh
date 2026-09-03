#!/bin/bash
# Validador de YAML para Schema Registry Subjects (standalone)
# Requisitos: yq (mikefarah) v4+ en el PATH
# Uso: ./validate_subjects.sh <ruta_yaml>
set -euo pipefail

########################################
# CONFIGURACIÓN
########################################

# (Opcional) Restringir properties[].name usando CSV:
# export ALLOWED_SR_PROPERTIES_CSV="azccdeu2peve02_bcp,otro_sr"
ALLOWED_SR_PROPERTIES_CSV="azccdeu2peve02_bcp,cfk"

# Igual que tu script de topics: <proyecto> permite minúsculas, números, guiones y punto (para excepción mm2-offset-syncs)
PROJECT_CHARS_CLASS=${PROJECT_CHARS_CLASS:-[a-z0-9.-]+}

# --- Control del <code4> por variable CODAPP (igual que tu script de topics)
CODAPP=$(echo "${CODAPP:-}" | tr '[:upper:]' '[:lower:]')
CODE4_RE='[a-z0-9]{4}'  # default

if [[ -n "${CODAPP:-}" ]]; then
  if [[ "$CODAPP" =~ ^[a-z0-9]{4}$ ]]; then
    CODE4_RE="$CODAPP"
    echo "ℹ️ Usando CODAPP='$CODAPP' como codigo de 4 caracteres fijos para validar nombres base."
  else
    echo "❌ Error: La variable CODAPP debe cumplir ^[a-z0-9]{4}$. Valor recibido: '$CODAPP'" >&2
    exit 1
  fi
fi

########################################
# FUNCIONES AUXILIARES
########################################
fail() { echo "❌ Error: $1" >&2; exit 1; }
info() { echo "✅ $1"; }

requires() {
  command -v "$1" >/dev/null || fail "Se requiere '$1' instalado y disponible en el PATH."
}

########################################
# LÓGICA DE NOMBRES (reutilizada de validate_topics.sh) 
########################################
valid_name() {
  local name="$1"

  # Excepciones explícitas
  local re_exc1='^_confluent-command$'
  local re_exc2="^mm2-offset-syncs\.${PROJECT_CHARS_CLASS}\.internal$"
  if [[ "$name" =~ $re_exc1 || "$name" =~ $re_exc2 ]]; then
    return 0
  fi

  # azc-connect: cfg-azc-connect-<code4>-<cola>... o azc-<code4>-<cola>... 
#  local re_azc_connect_base="^((cfg-azc-connect-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9]+$"
  local re_azc_connect_suffixes="^((cfg-azc-connect-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"

  # azc (BADI): cfg-azc-<code4>-<cola>... o azc-<code4>-<cola>... 
#  local re_azc_base="^((cfg-azc-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9]+$"
  local re_azc_suffixes="^((cfg-azc-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"

  # ks internos: terminan en -changelog o -repartition 
  local re_ks_internal="^ks-${CODE4_RE}-[a-z0-9-]+-(changelog|repartition)$"

  # if [[ "$name" =~ $re_azc_base ||
  #       "$name" =~ $re_azc_suffixes ||
  #       "$name" =~ $re_azc_connect_base ||
  #       "$name" =~ $re_azc_connect_suffixes ||
  #       "$name" =~ $re_ks_internal ]]; then
  #   return 0
  # fi

  if [[ "$name" =~ $re_azc_suffixes ||
        "$name" =~ $re_azc_connect_suffixes ||
        "$name" =~ $re_ks_internal ]]; then
    return 0
  fi

  return 1
}

# Subject estricto: base_topic + "-value"
# valid_subject_name() {
#   local subject="$1"

#   # Debe terminar exactamente en -value
#   [[ "$subject" == *-value ]] || return 1

#   # Base sin -value debe cumplir la misma lógica de nombres de tópicos
#   local base="${subject%-value}"
#   valid_name "$base"
# }

valid_subject_name() {
  local subject="$1"
  local base=""

  # Debe terminar exactamente en -value o -key
  if [[ "$subject" == *-value ]]; then
    base="${subject%-value}"
  elif [[ "$subject" == *-key ]]; then
    base="${subject%-key}"
  else
    return 1
  fi

  # Base sin sufijo debe cumplir la misma lógica de nombres de tópicos
  valid_name "$base"
}

########################################
# VALIDACIÓN ESTRUCTURAL YAML
########################################
requires yq

FILE="${1:-}"
[[ -n "$FILE" ]] || fail "Uso: $(basename "$0") <ruta_yaml>"
[[ -f "$FILE" ]] || fail "No se encontró el archivo: $FILE"

# # Primera línea significativa debe ser 'environment:'
# first_line_raw=$(awk 'BEGIN{FS=""} {
#   if ($0 ~ /^[[:space:]]*$/) next;
#   if ($0 ~ /^[[:space:]]*#/) next;
#   print $0; exit
# }' "$FILE")

# first_line=$(printf '%s' "$first_line_raw" | sed -E 's/^\xEF\xBB\xBF//' | tr -d '\r')
# trimmed=$(printf '%s' "$first_line" | sed -E 's/^[[:space:]]+//')

# if ! printf '%s' "$trimmed" | grep -Eq '^environment:[[:space:]]*$'; then
#   fail "El YAML debe iniciar exactamente con la línea 'environment:' (en la primera línea significativa). Línea encontrada: '$first_line_raw'"
# fi

# # Root: solo 'environment'
# ROOT_LEN=$(yq e '. | length' "$FILE")
# ROOT_KEYS=$(yq e '. | keys | .[]' "$FILE" 2>/dev/null || true)
# if [[ "$ROOT_LEN" -ne 1 || "$ROOT_KEYS" != "environment" ]]; then
#   fail "A nivel raíz solo debe existir la clave 'environment'. Encontrado: $(echo "$ROOT_KEYS" | paste -sd, -)"
# fi

# # environment: solo schema_registry
# ENV_LEN=$(yq e '.environment | length' "$FILE")
# ENV_KEYS=$(yq e '.environment | keys | .[]' "$FILE" 2>/dev/null || true)
# if [[ "$ENV_LEN" -ne 1 || "$ENV_KEYS" != "schema_registry" ]]; then
#   fail "En 'environment' sólo debe existir la clave 'schema_registry'. Encontrado: $(echo "$ENV_KEYS" | paste -sd, -)"
# fi











# Validar que el YAML comience exactamente con el tag 'environment:' (primera línea significativa)
# Ignora BOM, espacios en blanco iniciales, CRLF y comentarios '#...'
first_line_raw=$(awk 'BEGIN{FS=""} {
  if ($0 ~ /^[[:space:]]*$/) next;          # vacías
  if ($0 ~ /^[[:space:]]*#/) next;          # comentarios
  print $0; exit
}' "$FILE")
# Remover BOM y CR
first_line=$(printf '%s' "$first_line_raw" | sed -E 's/^\xEF\xBB\xBF//' | tr -d '\r')
# Quitar espacios/tabs al inicio
trimmed=$(printf '%s' "$first_line" | sed -E 's/^[[:space:]]+//')
# Comparar exactamente contra 'environment:' (sin nada más)
if ! printf '%s' "$trimmed" | grep -Eq '^environment:[[:space:]]*$'; then
  fail "❌ El YAML debe iniciar exactamente con la línea 'environment:' (en la primera línea significativa). Línea encontrada: '$first_line_raw'"
fi

# 'environment' debe aparecer exactamente una vez a nivel raíz
environment_KEY_COUNT=$(grep -E '^[[:space:]]*environment:' "$FILE" | wc -l | tr -d ' ')
[[ "$environment_KEY_COUNT" -eq 1 ]] || fail "La clave 'environment' debe existir exactamente una vez en el documento. Se encontraron $environment_KEY_COUNT ocurrencias."

# A nivel raíz solo 'environment'
ROOT_LEN=$(yq e '. | length' "$FILE")
ROOT_KEYS=$(yq e '. | keys | .[]' "$FILE" 2>/dev/null || true)
if [[ "$ROOT_LEN" -ne 1 || "$ROOT_KEYS" != "environment" ]]; then
  fail "A nivel raíz solo debe existir la clave 'environment'. Encontrado: $(echo "$ROOT_KEYS" | paste -sd, -)"
fi

# Debe existir 'environment'
yq e '.environment' "$FILE" >/dev/null || fail "Debe existir la clave 'environment'."

# En 'environment' solo 'schema_registry'
environment_LEN=$(yq e '.environment | length' "$FILE")
environment_KEYS=$(yq e '.environment | keys | .[]' "$FILE" 2>/dev/null || true)
if [[ "$environment_LEN" -ne 1 || "$environment_KEYS" != "schema_registry" ]]; then
  fail "En 'environment' sólo debe existir la clave 'schema_registry'. Encontrado: $(echo "$environment_KEYS" | paste -sd, -)"
fi

# En 'schema_registry' solo 'properties' y 'subjects'
schema_registry_KEYS_LIST=$(yq e '.environment.schema_registry | keys | .[]' "$FILE" 2>/dev/null || true)
[[ -n "$schema_registry_KEYS_LIST" ]] || fail "'schema_registry' no debe estar vacío."
while IFS= read -r key; do
  [[ "$key" == "properties" || "$key" == "subjects" ]] || fail "En 'schema_registry' sólo se permiten 'properties' y 'subjects'. Se encontró '$key'."
done <<< "$schema_registry_KEYS_LIST"

# 'subjects' única vez en 'schema_registry'
subjects_KEYS_COUNT=$(yq e '.environment.schema_registry | keys | .[]' "$FILE" 2>/dev/null | grep -c '^subjects$' || true)
[[ "$subjects_KEYS_COUNT" -eq 1 ]] || fail "'subjects' debe existir exactamente una vez en 'schema_registry'. Se encontraron $subjects_KEYS_COUNT ocurrencias."

# 'properties' a lo sumo una vez en 'schema_registry'
PROPERTIES_KEYS_COUNT=$(yq e '.environment.schema_registry | keys | .[]' "$FILE" 2>/dev/null | grep -c '^properties$' || true)
[[ "$PROPERTIES_KEYS_COUNT" -le 1 ]] || fail "'properties' debe existir a lo sumo una vez en 'schema_registry'. Se encontraron $PROPERTIES_KEYS_COUNT ocurrencias."

# Validar 'properties' si existe
PROP_EXISTS=$(yq e '.environment.schema_registry.properties // "__missing__"' "$FILE")
if [[ "$PROP_EXISTS" != "__missing__" ]]; then
  [[ $(yq e '.environment.schema_registry.properties | type' "$FILE") == "!!seq" ]] || fail "'properties' debe ser una lista (array)."
  PROP_COUNT=$(yq e '.environment.schema_registry.properties | length' "$FILE")
  for i in $(seq 0 $((PROP_COUNT-1))); do
    keys=$(yq e ".environment.schema_registry.properties[$i] | keys | .[]" "$FILE" 2>/dev/null | paste -sd, -)
    [[ "$keys" == "name" ]] || fail "Cada elemento de 'properties' sólo debe contener 'name'. Elemento $i contiene: $keys"
    val=$(yq e ".environment.schema_registry.properties[$i].name" "$FILE")
  done
fi


















# schema_registry: permitir properties y subjects
SR_KEYS=$(yq e '.environment.schema_registry | keys | .[]' "$FILE" 2>/dev/null || true)
[[ -n "$SR_KEYS" ]] || fail "'schema_registry' no debe estar vacío."

has_subjects=false
while IFS= read -r key; do
  if [[ "$key" == "subjects" ]]; then has_subjects=true; fi
  [[ "$key" == "properties" || "$key" == "subjects" ]] || fail "En 'schema_registry' sólo se permiten 'properties' y 'subjects'. Se encontró '$key'."
done <<< "$SR_KEYS"

[[ "$has_subjects" == true ]] || fail "'subjects' es obligatorio dentro de 'schema_registry'."

# Validar properties si existe (solo estructura; whitelist opcional por env var)
PROP_EXISTS=$(yq e '.environment.schema_registry.properties // "__missing__"' "$FILE")
if [[ "$PROP_EXISTS" != "__missing__" ]]; then
  [[ "$(yq e '.environment.schema_registry.properties | type' "$FILE")" == "!!seq" ]] || fail "'properties' debe ser una lista (array)."

  PROP_COUNT=$(yq e '.environment.schema_registry.properties | length' "$FILE")
  for i in $(seq 0 $((PROP_COUNT-1))); do
    keys=$(yq e ".environment.schema_registry.properties[$i] | keys | .[]" "$FILE" 2>/dev/null | paste -sd, -)
    [[ "$keys" == "name" ]] || fail "Cada elemento de 'properties' sólo debe contener 'name'. Elemento $i contiene: $keys"

    val=$(yq e ".environment.schema_registry.properties[$i].name" "$FILE")
    [[ -n "$val" && "$val" != "null" ]] || fail "'properties[$i].name' no puede ser null/vacío."

    if [[ -n "$ALLOWED_SR_PROPERTIES_CSV" ]]; then
      allowed=false
      IFS=',' read -r -a allowed_list <<< "$ALLOWED_SR_PROPERTIES_CSV"
      for ap in "${allowed_list[@]}"; do
        ap_trim="$(echo "$ap" | xargs)"
        [[ "$val" == "$ap_trim" ]] && allowed=true
      done
      [[ "$allowed" == true ]] || fail "'properties[$i].name' debe ser uno de: $ALLOWED_SR_PROPERTIES_CSV. Valor encontrado: '$val'"
    fi
  done
fi

# Validar subjects
type_subjects=$(yq e '.environment.schema_registry.subjects | type' "$FILE")
if [[ "$type_subjects" != "!!seq" && "$type_subjects" != "!!null" ]]; then
  fail "'subjects' debe ser una lista (array) o vacío."
fi

if [[ "$type_subjects" == "!!null" ]]; then
  SUBJECT_COUNT=0
else
  SUBJECT_COUNT=$(yq e '.environment.schema_registry.subjects | length' "$FILE")
fi

# No permitir duplicados
if [[ $SUBJECT_COUNT -gt 0 ]]; then
  NAMES=$(yq e '.environment.schema_registry.subjects[].name' "$FILE" 2>/dev/null || true)
  declare -A SEEN
  DUP=false
  DUPS_LIST=()

  while IFS= read -r n; do
    [[ -z "$n" || "$n" == "null" ]] && continue
    if [[ -n "${SEEN[$n]+x}" ]]; then
      DUP=true
      DUPS_LIST+=("$n")
    else
      SEEN[$n]=1
    fi
  done <<< "$NAMES"

  if [[ "$DUP" == true ]]; then
    fail "Existen nombres de subjects duplicados en 'environment.schema_registry.subjects': $(printf '%s ' "${DUPS_LIST[@]}" | sed 's/ $//')"
  fi
fi

# Validar cada subject
for i in $(seq 0 $((SUBJECT_COUNT-1))); do
  path=".environment.schema_registry.subjects[$i]"

  # Cada item debe tener solo name
  keys=$(yq e "$path | keys | .[]" "$FILE" 2>/dev/null | paste -sd, -)

  allowed_subject=false
  IFS=',' read -r -a allowed_keys_list <<< "$keys"
  for ap in "${allowed_keys_list[@]}"; do
    allowed_subject=false
	ap_trim="$(echo "$ap" | xargs)"
	[[ "$ap_trim" == "name" || "$ap_trim" == "context" || "$ap_trim" == "format" || "$ap_trim" == "compatibility_mode" ]] && allowed_subject=true
  done
  [[ "$allowed_subject" == true ]] || fail "Cada elemento de 'subjects' sólo debe contener 'name'. Elemento $i contiene: $keys"

  subject=$(yq e "$path.name" "$FILE")
  [[ -n "$subject" && "$subject" != "null" ]] || fail "El subject $i 'name' no puede ser null/vacío."

  # if ! valid_subject_name "$subject"; then
  #   if [[ "$subject" != *-value ]]; then
  #     fail "El subject $i 'name'='$subject' debe terminar en '-value'."
  #   else
  #     base="${subject%-value}"
  #     fail "El subject $i 'name'='$subject' no cumple: la base '$base' no respeta la nomenclatura de tópicos requerida."
  #   fi
  # fi

  if ! valid_subject_name "$subject"; then
    if [[ "$subject" != *-value && "$subject" != *-key ]]; then
      fail "El subject $i 'name'='$subject' es inválido: debe terminar en '-value' o '-key'."
    fi

    if [[ "$subject" == *-value ]]; then
      base="${subject%-value}"
    else
      base="${subject%-key}"
    fi

    fail "El subject $i 'name'='$subject' es inválido: la base '$base' no respeta la nomenclatura de tópicos requerida."
  fi
done








info "Validación de Schema Registry subjects completada correctamente."
