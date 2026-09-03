#!/bin/bash

# Validador de YAML para la estructura requerida
# Requisitos: yq (mikefarah) v4+ en el PATH
# Uso: . ./validate_topics.sh; validate_topics <ruta_al_yaml>

set -euo pipefail

#validate_topics() {

########################################
# CONFIGURACIÓN (plantilla / template)
########################################
#ALLOWED_PROPERTIES=("azure_eu2_kafka01" "azure_eu2_kafka02")
ALLOWED_PROPERTIES=("azure_eu2_kafka01")
ALLOWED_CLEANUP=("delete" "compact")
MAX_TOPICS=${MAX_TOPICS:-0}                       # 0 = sin límite; 'topics' puede tener 0..N
ALLOW_TIMESTAMP_TYPES=("LogAppendTime" "CreateTime")
ALLOW_TEMPLATES=${ALLOW_TEMPLATES:-true}
PROJECT_CHARS_CLASS=${PROJECT_CHARS_CLASS:-[a-z0-9.-]+}  # <proyecto> permite minúsculas, números, guiones y punto

CODAPP=$(echo "${CODAPP}" | tr '[:upper:]' '[:lower:]')

# --- NUEVO: control del <code4> por variable de entorno CODAPP ---
CODE4_RE='[a-z0-9]{4}'                   # valor por defecto (comportamiento anterior)
if [[ -n "${CODAPP:-}" ]]; then
  if [[ "$CODAPP" =~ ^[a-z0-9]{4}$ ]]; then
    CODE4_RE="$CODAPP"                   # restringir exactamente al valor de CODAPP
    echo "ℹ️ Usando CODAPP='$CODAPP' como codigo de 4 caracteres fijos en los nombres de los tópicos y su posterior validación."
  else
    echo "❌ Error: La variable CODAPP debe cumplir ^[a-z0-9]{4}$. Valor recibido: '$CODAPP'" >&2
    exit 1
  fi
fi

########################################
# FUNCIONES AUXILIARES
########################################
fail()      { echo "❌ Error: $1" >&2; exit 1; }
info()      { echo "✅ $1"; }
requires()  { command -v "$1" >/dev/null || fail "Se requiere '$1' instalado y disponible en el PATH."; }

is_template() {
  local val="$1"
  [[ "$val" =~ \{\{.*\}\} || "$val" =~ \$\{.*\} ]]
}

valid_name() {
  local name="$1"
  # Excepciones explícitas
  local re_exc1='^_confluent-command$'
  local re_exc2="^mm2-offset-syncs\.${PROJECT_CHARS_CLASS}\.internal$"
  if [[ "$name" =~ $re_exc1 ]] || [[ "$name" =~ $re_exc2 ]]; then return 0; fi

  # azc: cfg-azc-connect-<code4>-<cola>(-config|-status|-offset)?  |  azc-<code4>-<cola>(-config|-status|-offset)?
  local re_azc_connect_base="^((cfg-azc-connect-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9]+$"
  local re_azc_connect_suffixes="^((cfg-azc-connect-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"

  # BADI (Execpcion no encontrado en el estandar)
  # Ejemplo BADI. azc: cfg-azc-<code4>-<cola>(-config|-status|-offset)?  |  azc-<code4>-<cola>(-config|-status|-offset)?
  local re_azc_base="^((cfg-azc-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9]+$"
  local re_azc_suffixes="^((cfg-azc-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"
  # ks internos: terminan en -changelog o -repartition
  local re_ks_internal="^ks-${CODE4_RE}-[a-z0-9-]+-(changelog|repartition)$"

  if [[ "$name" =~ $re_azc_base ]] || [[ "$name" =~ $re_azc_suffixes ]] || \
     [[ "$name" =~ $re_azc_connect_base ]] || [[ "$name" =~ $re_azc_connect_suffixes ]] || \
     [[ "$name" =~ $re_ks_internal ]]; then
    return 0
  fi
  return 1
}

########################################
# VALIDACIÓN
########################################
requires yq

FILE="${1:-}"
[[ -n "$FILE" ]] || fail "Uso: $(basename "$0") <ruta_yaml>"
[[ -f "$FILE" ]] || fail "No se encontró el archivo: $FILE"

# Validar que el YAML comience exactamente con el tag 'cluster:' (primera línea significativa)
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
# Comparar exactamente contra 'cluster:' (sin nada más)
if ! printf '%s' "$trimmed" | grep -Eq '^cluster:[[:space:]]*$'; then
  fail "❌ El YAML debe iniciar exactamente con la línea 'cluster:' (en la primera línea significativa). Línea encontrada: '$first_line_raw'"
fi

# Rechazo explícito de clave mal escrita 'fcluster' en raíz
if grep -Eq '^[[:space:]]*fcluster:' "$FILE"; then
  fail "No se permite la clave raíz 'fcluster'. Debe ser únicamente 'cluster'."
fi

# 'cluster' debe aparecer exactamente una vez a nivel raíz
CLUSTER_KEY_COUNT=$(grep -E '^[[:space:]]*cluster:' "$FILE" | wc -l | tr -d ' ')
[[ "$CLUSTER_KEY_COUNT" -eq 1 ]] || fail "La clave 'cluster' debe existir exactamente una vez en el documento. Se encontraron $CLUSTER_KEY_COUNT ocurrencias."

# A nivel raíz solo 'cluster'
ROOT_LEN=$(yq e '. | length' "$FILE")
ROOT_KEYS=$(yq e '. | keys | .[]' "$FILE" 2>/dev/null || true)
if [[ "$ROOT_LEN" -ne 1 || "$ROOT_KEYS" != "cluster" ]]; then
  fail "A nivel raíz solo debe existir la clave 'cluster'. Encontrado: $(echo "$ROOT_KEYS" | paste -sd, -)"
fi

# Debe existir 'cluster'
yq e '.cluster' "$FILE" >/dev/null || fail "Debe existir la clave 'cluster'."

# En 'cluster' solo 'cc'
CLUSTER_LEN=$(yq e '.cluster | length' "$FILE")
CLUSTER_KEYS=$(yq e '.cluster | keys | .[]' "$FILE" 2>/dev/null || true)
if [[ "$CLUSTER_LEN" -ne 1 || "$CLUSTER_KEYS" != "cc" ]]; then
  fail "En 'cluster' sólo debe existir la clave 'cc'. Encontrado: $(echo "$CLUSTER_KEYS" | paste -sd, -)"
fi

# En 'cc' solo 'properties' y 'topics'
CC_KEYS_LIST=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null || true)
[[ -n "$CC_KEYS_LIST" ]] || fail "'cc' no debe estar vacío."
while IFS= read -r key; do
  [[ "$key" == "properties" || "$key" == "topics" ]] || fail "En 'cc' sólo se permiten 'properties' y 'topics'. Se encontró '$key'."
done <<< "$CC_KEYS_LIST"

# 'topics' única vez en 'cc'
TOPICS_KEYS_COUNT=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null | grep -c '^topics$' || true)
[[ "$TOPICS_KEYS_COUNT" -eq 1 ]] || fail "'topics' debe existir exactamente una vez en 'cc'. Se encontraron $TOPICS_KEYS_COUNT ocurrencias."

# 'properties' a lo sumo una vez en 'cc'
PROPERTIES_KEYS_COUNT=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null | grep -c '^properties$' || true)
[[ "$PROPERTIES_KEYS_COUNT" -le 1 ]] || fail "'properties' debe existir a lo sumo una vez en 'cc'. Se encontraron $PROPERTIES_KEYS_COUNT ocurrencias."

# Validar 'properties' si existe
PROP_EXISTS=$(yq e '.cluster.cc.properties // "__missing__"' "$FILE")
if [[ "$PROP_EXISTS" != "__missing__" ]]; then
  [[ $(yq e '.cluster.cc.properties | type' "$FILE") == "!!seq" ]] || fail "'properties' debe ser una lista (array)."
  PROP_COUNT=$(yq e '.cluster.cc.properties | length' "$FILE")
  for i in $(seq 0 $((PROP_COUNT-1))); do
    keys=$(yq e ".cluster.cc.properties[$i] | keys | .[]" "$FILE" 2>/dev/null | paste -sd, -)
    [[ "$keys" == "name" ]] || fail "Cada elemento de 'properties' sólo debe contener 'name'. Elemento $i contiene: $keys"
    val=$(yq e ".cluster.cc.properties[$i].name" "$FILE")
    if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$val"; then
      :
    else
      allowed=false
      for ap in "${ALLOWED_PROPERTIES[@]}"; do [[ "$val" == "$ap" ]] && allowed=true; done
      [[ "$allowed" == true ]] || fail "'properties[$i].name' debe ser uno de: ${ALLOWED_PROPERTIES[*]}. Valor encontrado: '$val'"
    fi
  done
fi

# Validar 'topics'
yq e '.cluster.cc.topics' "$FILE" >/dev/null || fail "'topics' debe existir dentro de 'cc'."
type_topics=$(yq e '.cluster.cc.topics | type' "$FILE")
if [[ "$type_topics" != "!!seq" && "$type_topics" != "!!null" ]]; then
  fail "'topics' debe ser una lista (array) o vacío."
fi

# Contar tópicos (0 si es null)
if [[ "$type_topics" == "!!null" ]]; then
  TOPIC_COUNT=0
else
  TOPIC_COUNT=$(yq e '.cluster.cc.topics | length' "$FILE")
fi

# Límite máximo si se configuró
if [[ "$MAX_TOPICS" -gt 0 && "$TOPIC_COUNT" -gt "$MAX_TOPICS" ]]; then
  fail "El arreglo 'topics' tiene $TOPIC_COUNT elementos y supera el máximo permitido ($MAX_TOPICS)."
fi

# No permitir names duplicados
if [[ $TOPIC_COUNT -gt 0 ]]; then
  NAMES=$(yq e '.cluster.cc.topics[].name' "$FILE" 2>/dev/null || true)
  declare -A SEEN
  DUP=false
  DUPS_LIST=()
  while IFS= read -r n; do
    [[ -z "$n" ]] && continue
    if [[ -n "${SEEN[$n]+x}" ]]; then
      DUP=true
      DUPS_LIST+=("$n")
    else
      SEEN[$n]=1
    fi
  done <<< "$NAMES"
  if [[ "$DUP" == true ]]; then
    fail "Existen nombres de tópicos duplicados en 'cluster.cc.topics': $(printf '%s ' "${DUPS_LIST[@]}" | sed 's/ $//')"
  fi
fi

# Validar cada tópico (si hay)
for i in $(seq 0 $((TOPIC_COUNT-1))); do
  path=.cluster.cc.topics[$i]
  # Claves obligatorias
  for k in name partitions config; do
    yq e "$path.$k" "$FILE" >/dev/null || fail "El tópico $i debe contener la clave obligatoria '$k'."
  done
  # Un único nivel por tópico
  TOPIC_TOP_KEYS=$(yq e "$path | keys | .[]" "$FILE" 2>/dev/null || true)
  while IFS= read -r tkey; do
    [[ "$tkey" == "name" || "$tkey" == "partitions" || "$tkey" == "config" ]] || fail "El tópico $i contiene clave no permitida: '$tkey'"
  done <<< "$TOPIC_TOP_KEYS"

  # name (patrón + excepciones)
  name=$(yq e "$path.name" "$FILE")
  if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$name"; then
    :
  else
    valid_name "$name" || fail "El tópico $i 'name'='$name' no cumple el patrón requerido ni las excepciones."
  fi

  # partitions numérico
  parts=$(yq e "$path.partitions" "$FILE")
  [[ "$parts" =~ ^[0-9]+$ ]] || fail "El tópico $i 'partitions' debe ser numérico. Valor: '$parts'"

  # config objeto + claves obligatorias
  [[ $(yq e "$path.config | type" "$FILE") == "!!map" ]] || fail "El tópico $i 'config' debe ser un objeto (map)."
  for ck in cleanup.policy min.insync.replicas; do
    yq e "$path.config.\"$ck\"" "$FILE" >/dev/null || fail "El tópico $i 'config' debe incluir '$ck'."
  done

  # cleanup.policy (solo delete | compact)
  cp=$(yq e "$path.config.\"cleanup.policy\"" "$FILE")
  if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$cp"; then
    :
  else
    allowed=false
    for ac in "${ALLOWED_CLEANUP[@]}"; do [[ "$cp" == "$ac" ]] && allowed=true; done
    [[ "$allowed" == true ]] || fail "El tópico $i 'cleanup.policy' debe ser uno de: ${ALLOWED_CLEANUP[*]}. Valor: '$cp'"
  fi

  # min.insync.replicas numérico
  mir=$(yq e "$path.config.\"min.insync.replicas\"" "$FILE")
  if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$mir"; then
    :
  else
    [[ "$mir" =~ ^[0-9]+$ ]] || fail "El tópico $i 'min.insync.replicas' debe ser numérico. Valor: '$mir'"
  fi

  # message.timestamp.type opcional y restringible
  mts_exists=$(yq e "$path.config.\"message.timestamp.type\" // \"__missing__\"" "$FILE")
  if [[ "$mts_exists" != "__missing__" ]]; then
    mts="$mts_exists"
    if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$mts"; then
      :
    else
      if [[ ${#ALLOW_TIMESTAMP_TYPES[@]} -gt 0 ]]; then
        allowed=false
        for at in "${ALLOW_TIMESTAMP_TYPES[@]}"; do [[ "$mts" == "$at" ]] && allowed=true; done
        [[ "$allowed" == true ]] || fail "El tópico $i 'message.timestamp.type' debe ser uno de: ${ALLOW_TIMESTAMP_TYPES[*]}. Valor: '$mts'"
      fi
    fi
  fi

  # retention.ms opcional numérico
  rm_exists=$(yq e "$path.config.\"retention.ms\" // \"__missing__\"" "$FILE")
  if [[ "$rm_exists" != "__missing__" ]]; then
    if [[ "$ALLOW_TEMPLATES" == true ]] && is_template "$rm_exists"; then
      :
    else
      [[ "$rm_exists" =~ ^[0-9]+$ ]] || fail "El tópico $i 'retention.ms' debe ser numérico. Valor: '$rm_exists'"
    fi
  fi

done

info "Validación completada correctamente."

#}

