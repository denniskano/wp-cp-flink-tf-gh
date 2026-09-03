#!/usr/bin/env bash
# Validador de YAML para RBAC (cluster.*.rbac) - standalone
# Requisitos: yq (mikefarah) v4+ en el PATH
# Uso: ./validate_rbac.sh <ruta_yaml>
set -euo pipefail
ALLOWED_PROPERTIES=("azure_eu2_kafka01")

fail() { echo "❌ Error: $1" >&2; exit 1; }
info() { echo "✅ $1"; }
requires() { command -v "$1" >/dev/null 2>&1 || fail "Se requiere '$1' instalado y disponible en el PATH."; }

# -----------------------------
# -----------------------------
PROJECT_CHARS_CLASS=${PROJECT_CHARS_CLASS:-[a-z0-9.-]+}
CODE4_RE='[a-z0-9]{4}'

valid_name() {
  local name="$1"
  local re_exc1='^_confluent-command$'
  local re_exc2="^mm2-offset-syncs\\.${PROJECT_CHARS_CLASS}\\.internal$"
  if [[ "$name" =~ $re_exc1 || "$name" =~ $re_exc2 ]]; then
    return 0
  fi

  # azc-connect
  local re_azc_connect_suffixes="^((cfg-azc-connect-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"

  # azc
  local re_azc_suffixes="^((cfg-azc-${CODE4_RE})|(azc-${CODE4_RE}))-[a-z0-9-]+(-(config|status|offset))?$"

  # MIRROR cloud-glb-codapp, cloud-loc-codapp, onprem-glb-codapp, onprem-loc-codapp, 
  local re_mirror_base_cfk_mrco="^((loc-${CODE4_RE})|(cc-glb-${CODE4_RE})|(cc-loc-${CODE4_RE})|(cloud-glb-${CODE4_RE})|(cloud-loc-${CODE4_RE})|(onprem-glb-${CODE4_RE})|(onprem-loc-${CODE4_RE}))-[a-z0-9]+(-[a-z0-9]+)*$"

  # ks internos
  local re_ks_internal="^ks-${CODE4_RE}-[a-z0-9-]+-(changelog|repartition)$"

  [[ "$name" =~ $re_azc_suffixes ||
     "$name" =~ $re_azc_connect_suffixes ||
     "$name" =~ $re_mirror_base_cfk_mrco ||
     "$name" =~ $re_ks_internal ]]
}

valid_name_ks() {
  local name="$1"

  # ks internos
  local re_ks_internal="^ks-${CODE4_RE}-[a-z0-9-]+(-(changelog|repartition))?$"
  #local re_ks_internal="^((ks-${CODE4_RE}))-[a-z0-9]+(-[a-z0-9]+)*$"

  [[ "$name" =~ $re_ks_internal ]]

}

# Inferir CODAPP (4 chars) desde el principal.
# Estrategia: tomar el primer token (separado por '_') que tenga exactamente 4 chars alfanum.
# Se convierte a minúsculas y se valida ^[a-z]{4}$.
# infer_codapp() {
#   local principal="$1"
#   local tok
#   IFS='_' read -r -a parts <<< "$principal"
#   for tok in "${parts[@]}"; do
#     if [[ "$tok" =~ ^[A-Za-z0-9]{4}$ ]]; then
#       tok="${tok,,}"
#       if [[ "$tok" =~ ^[a-z]{4}$ ]]; then
#         echo "$tok"
#         return 0
#       fi
#     fi
#   done
#   return 1
# }

# Verifica que un mapping tenga solo ciertas llaves (sin importar orden)
# args: path keys_csv
assert_only_keys() {
  local path="$1"; shift
  local allowed_csv="$1"; shift
  local keys
  keys=$(yq e "$path | keys | .[]" "$FILE" 2>/dev/null || true)
  [[ -n "$keys" ]] || fail "'$path' no debe estar vacío."

  local allowed=()
  IFS=',' read -r -a allowed <<< "$allowed_csv"

  local k
  while IFS= read -r k; do
    local ok=false
    local a
    for a in "${allowed[@]}"; do
      a="$(echo "$a" | xargs)"
      if [[ "$k" == "$a" ]]; then ok=true; break; fi
    done
    [[ "$ok" == true ]] || fail "En '$path' solo se permiten las claves: $allowed_csv. Se encontró '$k'."
  done <<< "$keys"
}

# Validación específica de llaves para cada resource (resource_region opcional SOLO para compute-pool)
assert_resource_keys() {
  local rpath="$1"
  local rtype="$2"

  local keys
  keys=$(yq e "$rpath | keys | .[]" "$FILE" 2>/dev/null || true)
  [[ -n "$keys" ]] || fail "'$rpath' no debe estar vacío."

  local base_allowed=(resource_type resource_name pattern_type role)
  local allow_region=false
  [[ "$rtype" == "compute-pool" ]] && allow_region=true

  local k
  while IFS= read -r k; do
    local ok=false
    local a
    for a in "${base_allowed[@]}"; do
      [[ "$k" == "$a" ]] && ok=true && break
    done

    if [[ "$ok" == false && "$k" == "resource_region" ]]; then
      [[ "$allow_region" == true ]] || fail "La clave 'resource_region' solo está permitida cuando resource_type='compute-pool'. Error en '$rpath'."
      ok=true
    fi

    [[ "$ok" == true ]] || fail "En '$rpath' solo se permiten las claves: resource_type, resource_name, pattern_type, role${allow_region:+, resource_region}. Se encontró '$k'."
  done <<< "$keys"
}

# Lee operaciones (role[].operation) a un array global OPS
read_ops() {
  local role_path="$1"
  mapfile -t OPS < <(yq e "$role_path[].operation" "$FILE" 2>/dev/null || true)
  # Limpieza de 'null'
  local cleaned=()
  local op
  for op in "${OPS[@]:-}"; do
    [[ -n "$op" && "$op" != "null" ]] && cleaned+=("$op")
  done
  OPS=("${cleaned[@]:-}")
}

# -----------------------------
# MAIN
# -----------------------------
requires yq

FILE="${1:-}"
[[ -n "$FILE" ]] || fail "Uso: $(basename "$0") <ruta_yaml>"
[[ -f "$FILE" ]] || fail "No se encontró el archivo: $FILE"

# # Root: solo 'cluster'
# root_len=$(yq e '. | length' "$FILE")
# root_keys=$(yq e '. | keys | .[]' "$FILE" 2>/dev/null || true)
# [[ "$root_len" -eq 1 && "$root_keys" == "cluster" ]] || fail "A nivel raíz solo debe existir la clave 'cluster'. Encontrado: $(echo "$root_keys" | paste -sd, -)"


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

# En 'cc' solo 'properties' y 'rbac'
CC_KEYS_LIST=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null || true)
[[ -n "$CC_KEYS_LIST" ]] || fail "'cc' no debe estar vacío."
while IFS= read -r key; do
  [[ "$key" == "properties" || "$key" == "rbac" ]] || fail "En 'cc' sólo se permiten 'properties' y 'rbac'. Se encontró '$key'."
done <<< "$CC_KEYS_LIST"

# 'rbac' única vez en 'cc'
rbac_KEYS_COUNT=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null | grep -c '^rbac$' || true)
[[ "$rbac_KEYS_COUNT" -eq 1 ]] || fail "'rbac' debe existir exactamente una vez en 'cc'. Se encontraron $rbac_KEYS_COUNT ocurrencias."

# 'properties' a lo sumo una vez en 'cc'
PROPERTIES_KEYS_COUNT=$(yq e '.cluster.cc | keys | .[]' "$FILE" 2>/dev/null | grep -c '^properties$' || true)
[[ "$PROPERTIES_KEYS_COUNT" -le 1 ]] || fail "'properties' debe existir a lo sumo una vez en 'cc'. Se encontraron $PROPERTIES_KEYS_COUNT ocurrencias."

# Validar 'properties' si existe
PROP_EXISTS=$(yq e '.cluster.cc.properties // "__missing__"' "$FILE")
allowed=false
if [[ "$PROP_EXISTS" != "__missing__" ]]; then
  [[ $(yq e '.cluster.cc.properties | type' "$FILE") == "!!seq" ]] || fail "'properties' debe ser una lista (array)."
  PROP_COUNT=$(yq e '.cluster.cc.properties | length' "$FILE")

  for i in $(seq 0 $((PROP_COUNT-1))); do
    keys=$(yq e ".cluster.cc.properties[$i] | keys | .[]" "$FILE" 2>/dev/null | paste -sd, -)
    [[ "$keys" == "name" ]] || fail "Cada elemento de 'properties' sólo debe contener 'name'. Elemento $i contiene: $keys"
    val=$(yq e ".cluster.cc.properties[$i].name" "$FILE")
    for ap in "${ALLOWED_PROPERTIES[@]}"; do [[ "$val" == "$ap" ]] && allowed=true; done
    [[ "$allowed" == true ]] || fail "'properties[$i].name' debe ser uno de: ${ALLOWED_PROPERTIES[*]}. Valor encontrado: '$val'"
  done
else
	fail "'cluster.cc.properties' debe contener name."
fi










# cluster debe ser mapping
[[ "$(yq e '.cluster | type' "$FILE")" == "!!map" ]] || fail "'cluster' debe ser un objeto (map)."

# Iterar clusters (ej: cc)
mapfile -t CLUSTERS < <(yq e '.cluster | keys | .[]' "$FILE" 2>/dev/null || true)
[[ ${#CLUSTERS[@]} -gt 0 ]] || fail "'cluster' debe contener al menos un entorno (por ejemplo: 'cc')."

for c in "${CLUSTERS[@]}"; do
  cpath=".cluster.${c}"
  [[ "$(yq e "$cpath | type" "$FILE")" == "!!map" ]] || fail "'$cpath' debe ser un objeto (map)."

  # Solo properties y rbac (properties opcional, rbac requerido)
  assert_only_keys "$cpath" "properties,rbac"

  # properties
  prop_type=$(yq e "$cpath.properties | type" "$FILE" 2>/dev/null || echo "!!null")
  if [[ "$prop_type" != "!!null" ]]; then
    [[ "$prop_type" == "!!seq" ]] || fail "'$cpath.properties' debe ser una lista (array)."
    prop_len=$(yq e "$cpath.properties | length" "$FILE")
    for i in $(seq 0 $((prop_len-1))); do
      pitem="$cpath.properties[$i]"
      assert_only_keys "$pitem" "name"
      pname=$(yq e "$pitem.name" "$FILE")
      [[ -n "$pname" && "$pname" != "null" ]] || fail "'$pitem.name' no puede ser null/vacío."
    done
  fi

  # rbac requerido
  rbac_type=$(yq e "$cpath.rbac | type" "$FILE" 2>/dev/null || echo "!!null")
#  [[ "$rbac_type" == "!!seq" ]] || fail "'$cpath.rbac' es obligatorio y debe ser una lista (array)."
  rbac_len=$(yq e "$cpath.rbac | length" "$FILE")

  for i in $(seq 0 $((rbac_len-1))); do
    ipath="$cpath.rbac[$i]"
    assert_only_keys "$ipath" "principal,resources"

    principal=$(yq e "$ipath.principal" "$FILE")
    [[ -n "$principal" && "$principal" != "null" ]] || fail "'$ipath.principal' no puede ser null/vacío."

	# 1. Obtiene el nombre del archivo: xx-rbac-{env}.yaml
	nombre_archivo="${FILE##*/}"
	# 2. Extrae los 3 caracteres previos a la extensión: des
	entorno="${nombre_archivo%.yaml}"
	entorno="${entorno##*-}"
	# 3. Convierte el valor a mayúsculas: DES
	AMBIENTE="${entorno^^}"

	if [[ ! ("$AMBIENTE" == "DES" && "$principal" == "APPOFHAPSYKAFKADES") ]]; then
		[[ "$principal" =~ ^((SA_AZC_${AMBIENTE}_[A-Z0-9]{4}))_[A-Z0-9]+(_[A-Z0-9]+)*$ ]] || fail "principal = '$principal' no cumple los requisitos de nombre o ambiente, en '$ipath'"
	fi
	
    res_type=$(yq e "$ipath.resources | type" "$FILE" 2>/dev/null || echo "!!null")
    [[ "$res_type" == "!!seq" ]] || fail "'$ipath.resources' es obligatorio y debe ser una lista (array)."
    res_len=$(yq e "$ipath.resources | length" "$FILE")
    [[ $res_len -gt 0 ]] || fail "'$ipath.resources' no debe estar vacío."

    for j in $(seq 0 $((res_len-1))); do
      rpath="$ipath.resources[$j]"

      resource_type=$(yq e "$rpath.resource_type" "$FILE")
      [[ -n "$resource_type" && "$resource_type" != "null" ]] || fail "'$rpath.resource_type' no puede ser null/vacío."

      case "$resource_type" in
        topic|group|subject|compute-pool|transactional-id) : ;;
        *) fail "'$rpath.resource_type'='$resource_type' no es válido. Permitidos: topic, group, subject, compute-pool, transactional-id." ;;
      esac

      # Validar llaves del resource (con condicion para resource_region)
      assert_resource_keys "$rpath" "$resource_type"

      resource_name=$(yq e "$rpath.resource_name" "$FILE")
      pattern_type=$(yq e "$rpath.pattern_type" "$FILE")

      [[ -n "$resource_name" && "$resource_name" != "null" ]] || fail "'$rpath.resource_name' no puede ser null/vacío."
      [[ -n "$pattern_type" && "$pattern_type" != "null" ]] || fail "'$rpath.pattern_type' no puede ser null/vacío."

      case "$pattern_type" in
        LITERAL|PREFIXED) : ;;
        *) fail "'$rpath.pattern_type'='$pattern_type' no es válido. Permitidos: LITERAL, PREFIXED." ;;
      esac

      # resource_region opcional SOLO compute-pool
      if [[ "$resource_type" == "compute-pool" ]]; then
        region=$(yq e "$rpath.resource_region // \"__missing__\"" "$FILE")
        if [[ "$region" != "__missing__" ]]; then
          [[ -n "$region" && "$region" != "null" ]] || fail "'$rpath.resource_region' no puede ser null/vacío cuando se define para compute-pool."
        fi
      fi

      # role
      role_type=$(yq e "$rpath.role | type" "$FILE" 2>/dev/null || echo "!!null")
      [[ "$role_type" == "!!seq" ]] || fail "'$rpath.role' es obligatorio y debe ser una lista (array)."
      read_ops "$rpath.role"
      [[ ${#OPS[@]} -gt 0 ]] || fail "'$rpath.role' debe contener al menos un 'operation'."

      # Validar operaciones conocidas
      has_resource_owner=false
      for op in "${OPS[@]}"; do
        case "$op" in
          DeveloperRead|DeveloperWrite|ResourceOwner|FlinkDeveloper) : ;;
          *) fail "Operación no permitida '$op' en '$rpath.role[].operation'." ;;
        esac
        [[ "$op" == "ResourceOwner" ]] && has_resource_owner=true
      done

      # Regla: si existe ResourceOwner => pattern_type LITERAL
#      if [[ "$has_resource_owner" == true && "$pattern_type" != "LITERAL" ]]; then
      if [[ "$has_resource_owner" == true && "$pattern_type" != "LITERAL" && "$resource_name" != ks-* ]]; then
        fail "Regla ResourceOwner: si role.operation incluye 'ResourceOwner', entonces pattern_type debe ser 'LITERAL'. Encontrado pattern_type='$pattern_type' en '$rpath'."
      fi

      # Regla: compute-pool => operation permitido FlinkDeveloper (y solo ese)
      if [[ "$resource_type" == "compute-pool" ]]; then
        for op in "${OPS[@]}"; do
          [[ "$op" == "FlinkDeveloper" ]] || fail "Para resource_type='compute-pool' solo se permite operation='FlinkDeveloper'. Encontrado '$op' en '$rpath.role'."
        done
      fi

      # Regla: resource_name == '*' solo permitido para subject y con DeveloperRead
      if [[ "$resource_name" == "*" ]]; then
        [[ "$resource_type" == "subject" ]] || fail "resource_name='*' solo está permitido cuando resource_type='subject'. Error en '$rpath'."
        for op in "${OPS[@]}"; do
          [[ "$op" == "DeveloperRead" ]] || fail "resource_name='*' requiere operation='DeveloperRead' únicamente. Encontrado '$op' en '$rpath.role'."
        done
      fi

      # Reglas específicas
      if [[ "$resource_type" == "group" ]]; then
        # operation solo DeveloperRead
        for op in "${OPS[@]}"; do
          [[ "$op" == "DeveloperRead" ]] || fail "Para resource_type='group' solo se permite operation='DeveloperRead'. Encontrado '$op' en '$rpath.role'."
        done

        if [[ ! "$resource_name" =~ ^(cloud-customer-case-validate-cg01|cloud-customer-case-rule-engine-cg01|async-aptb-account-monetary-operation-v1-cg-01|async-aptb-account-non-monetary-operation-v1-cg-01|async-aptb-card-operation-v1-cg-01|async-aptb-unsuccess-operation-v1-cg-01|msv-attention-order-cg|msv-response-letter-cg|msv-sheet-claim-cg|msv-online-payment-cg) ]]; then
#           re_consumer_group="^((azc-${CODE4_RE})|(cloud-${CODE4_RE})|(async-${CODE4_RE})|(ks-${CODE4_RE}))-[a-z0-9]+(-[a-z0-9]+)*$"
           re_consumer_group="^((azc)|(cloud-${CODE4_RE})|(cfg-azc-connect-${CODE4_RE})|(connect-connect-${CODE4_RE})|(connect-${CODE4_RE})|(ks-${CODE4_RE}))-[a-z0-9]+(-[a-z0-9]+)*$"
		
		  [[ "$resource_name" =~ $re_consumer_group ]] || fail "Para resource_type='group', resource_name debe iniciar con 'azc-<nombre del componente|service-name>-cg<index>', 'ks-codapp-' o 'cloud-codapp-'. Encontrado '$resource_name' en '$rpath.resource_name'."
	 
        fi


      fi

      if [[ "$resource_type" == "topic" ]]; then
        # Validar nomenclatura (con code4 libre)
		if [[ "$resource_name" == ks-* ]] && ! valid_name_ks "$resource_name"; then
          fail "Nombre de topic ks-* inválido '$resource_name' en '$rpath.resource_name'."
        fi
        if [[ "$resource_name" != ks-* ]] && ! valid_name "$resource_name"; then
          fail "Nombre de topic inválido '$resource_name' en '$rpath.resource_name'."
        fi
        # topic que empieza con azc- => solo DeveloperWrite/DeveloperRead
        #if [[ "$resource_name" == azc-* ]]; then
        if [[ ! ("$resource_name" == ks-*)  ]]; then
          for op in "${OPS[@]}"; do
			if [[ ! ("$resource_name" == cfg-* || "$resource_name" == mm2-offset-syncs.*) ]]; then
				[[ "$op" == "DeveloperRead" || "$op" == "DeveloperWrite" ]] || fail "Para topics 'azc-*' [$resource_name] solo se permiten operaciones DeveloperRead y DeveloperWrite. Encontrado '$op' en '$rpath.role'."			
				[[ ("$op" == "DeveloperRead" || "$op" == "DeveloperWrite") && "$pattern_type" == "LITERAL" ]] || fail "Para topics 'azc-*' [$resource_name] el pattern_type debe ser 'LITERAL'. Encontrado pattern_type='$pattern_type' en '$rpath.role'.."
			else
				[[ "$op" == "DeveloperRead" || "$op" == "DeveloperWrite" || "$op" == "ResourceOwner" ]] || fail "Para topics 'cfg-*' o 'mm2-offset-syncs.*' [$resource_name] solo se permiten operaciones DeveloperRead, DeveloperWrite y ResourceOwner. Encontrado '$op' en '$rpath.role'."			
				[[ ("$op" == "DeveloperRead" || "$op" == "DeveloperWrite"  || "$op" == "ResourceOwner") && "$pattern_type" == "LITERAL" ]] || fail "Para topics 'cfg-*' o 'mm2-offset-syncs.*' [$resource_name] el pattern_type debe ser 'LITERAL'. Encontrado pattern_type='$pattern_type' en '$rpath.role'.."			
			fi
          done
        fi
      fi

#      if [[ "$resource_type" == "subject" ]]; then
#        # '-value' es de libre uso: NO se valida sufijo
#        :
#      fi
      if [[ "$resource_type" == "subject" && "$resource_name" != "*" ]]; then
        # Validar nomenclatura (con code4 libre)
        
		if [[ "$resource_name" == ks-* ]] && ! valid_name_ks "$resource_name"; then
          fail "Nombre de subject inválido '$resource_name' en '$rpath.resource_name'."		
		fi
		if [[ "$resource_name" != ks-* ]] && ! valid_name "$resource_name"; then
          fail "Nombre de subject inválido '$resource_name' en '$rpath.resource_name'."
        fi
		
        # subject que empieza con azc- => solo DeveloperWrite/DeveloperRead
        #if [[ "$resource_name" == azc-* ]]; then
        if [[ ! ("$resource_name" == ks-*)  ]]; then
          for op in "${OPS[@]}"; do
			#INICIO - Solo Pruebas ICDC DESARROLLO 
			#if [[ "$resource_name" == azc-icdc-nextday- ]]; then
			#   continue
			#fi
			#FIN - Solo Pruebas ICDC DESARROLLO 
			
            #[[ "$op" == "DeveloperRead" || "$op" == "DeveloperWrite" ]] || fail "Para subject 'azc-*' solo se permiten operaciones DeveloperRead y DeveloperWrite. Encontrado '$op' en '$rpath.role'."
            [[ "$op" == "DeveloperRead" ]] || fail "Para subject 'azc-*' [$resource_name] solo se permiten operaciones DeveloperRead. Encontrado '$op' en '$rpath.role'."

			#if [[ "$op" != "DeveloperRead" && "$pattern_type" != "LITERAL" ]]; then
			#   fail "(subject)Regla diferente a DeveloperRead: si role.operation incluye '$op', entonces pattern_type debe ser 'LITERAL'. Encontrado pattern_type='$pattern_type' en '$rpath.role'."
			#fi

          done
        fi

		
      fi

      # transactional-id: por ahora solo validación estructural y operaciones permitidas (sin reglas extra)

    done
  done

done


# No permitir PRINCIPAL_NAME duplicados
PRINCIPAL_NAME=$(yq e '.cluster.cc.rbac[].principal' "$FILE" 2>/dev/null || true)
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
done <<< "$PRINCIPAL_NAME"
if [[ "$DUP" == true ]]; then
fail "Existen nombres de service account duplicados en '.cluster.cc.rbac': $(printf '%s ' "${DUPS_LIST[@]}" | sed 's/ $//')"
fi


info "Validación RBAC completada correctamente."

