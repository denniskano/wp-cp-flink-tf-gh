#!/bin/bash
set -euo pipefail
##### ARGS[] #####
#CODAPP=PEVE #$1
export ORGANIZATION_ID=$1   #"15995726-1235-4553-a51c-746675ad89e4"
export ENVIRONMENT_ID=$2    #"env-156n66"
export CATALOG_NAME=$3      #"bcp_desa"
export CLUSTER_NAME=$4      #"AZURE_EU2_DESA_KAFKA01"
#
TF_VAR_flink_credentials=$(echo "$5" | base64 -d)
RELATIVE_SUBPATH_SRC=$6     #"/mnt/d/Utilitarios/Terraform/PEVE-PARTNER/ccloud-flink-statements"
export ENVIRONMENT=$7       #"DES"
RELATIVE_SUBPATH_TERRAFORM=$8
#
#
#
: "${FLINK_PRIVATE_REST_ENDPOINT:=}"
: "${PATH_HV_APP:=}"
: "${VAR_confluent_flink_api_key:=}"
: "${VAR_confluent_flink_api_secret:=}"
echo "FLINK_PRIVATE_REST_ENDPOINT:$FLINK_PRIVATE_REST_ENDPOINT"
echo "PATH_HV_APP=$PATH_HV_APP; para validar si se pueden usar variables de entorno en estos script anidados"
#
#
#
##### SET PATHS: DIRECTORY DDL DML AUTOMATIONS #####
AUTOMATION_DIRNAME="./resources"
echo "AUTOMATION_DIRNAME: $AUTOMATION_DIRNAME"
YAML_FILES_DDL_PATH="${RELATIVE_SUBPATH_SRC}/ddl"
echo "YAML_FILES_DDL_PATH: $YAML_FILES_DDL_PATH"
YAML_FILES_DML_PATH="${RELATIVE_SUBPATH_SRC}/dml"
echo "YAML_FILES_DML_PATH: $YAML_FILES_DML_PATH"
#
#
#
########## INI - FUNCTIONS ##########
#
require_var() {
  local var_name="$1"
  local err_msg="$2"
  if [ -z "$var_name" ] || [ "x$var_name" == "x" ] || [ "$var_name" == null ]; then
    echo "ERROR: $err_msg" >&2
    exit 1
  fi
}

# apply: omitido/managed | ignore | once  (igual que flink-v1)
yaml_apply() {
  local f="$1"
  local v
  v=$(grep -E '^apply:' "$f" | head -1 | awk -F: '{print $2}' | tr -d ' "' | tr '[:upper:]' '[:lower:]' || true)
  echo "${v:-managed}"
}

# properties: del YAML, más catalog/database (carry-over = sql.tables.initial-offset-from)
yaml_properties_hcl() {
  local f="$1"
  printf '    "sql.current-catalog"  = "%s"\n' "${CATALOG_NAME}"
  printf '    "sql.current-database" = "%s"\n' "${CLUSTER_NAME}"
  if command -v yq >/dev/null; then
    yq -r '
      (.properties // {}) | to_entries[] |
      "    \"" + .key + "\" = \"" + (.value | tostring | sub("\""; "\\\"")) + "\""
    ' "$f"
    return
  fi
  awk '
    $0 ~ /^properties:[[:space:]]*$/ { p=1; next }
    p && /^[^[:space:]#]/ { exit }
    p && /^[[:space:]]+[#]/ { next }
    p && /^[[:space:]]+[A-Za-z0-9._-]+:/ {
      line=$0
      sub(/^[[:space:]]+/, "", line)
      key=line
      sub(/:.*$/, "", key)
      val=line
      sub(/^[^:]+:[[:space:]]*/, "", val)
      gsub(/^["'\'']|["'\'']$/, "", val)
      gsub(/"/, "\\\"", val)
      printf "    \"%s\" = \"%s\"\n", key, val
    }
  ' "$f"
}
#Map search TF_VAR_flink_credentials
get_value_from_input() {
  local input="$1"
  local map_key="$2"
  local field="$3"
  value=$(echo "$input" | jq -r --arg k "$map_key" --arg f "$field" '.[$k][$f] // empty')
  if [ "x$value" == "x" ]; then
    echo "Error: $value is null."
    exit 1
  fi
  echo "$value"
}
#Create resource: ddl o dml
# $6 opcional: only_apply (ej. once). Vacío = todos los YAML del dir.
load_file_stmts_all(){
  local stmts_path=$1
  local flink_credentials=$2
  local tf_stmt_final=$3
  local tpl_stmt=$4
  local list_cps=$5
  local only_apply="${6:-}"
  local tmp
  tmp="$(mktemp)"
  trap 'rm -f "'"$tmp"'"' RETURN
  #
  for stmt in "$stmts_path"/*.yaml; do
    sed "s/\${environment}/${ENVIRONMENT}/g" $stmt > "$tmp"
    export STATEMENT_NAME=$(grep '^statement-name:' "$tmp" | awk -F: '{print $2}' | tr -d ' "')
    export COMPUTE_POOL=$(grep '^flink-compute-pool:' "$tmp" | awk -F: '{print $2}' | tr -d ' "')
    export STOPPED=$(grep '^stopped:' "$tmp" | awk -F: '{print $2}' | tr -d ' "')
    export PRINCIPAL=$(grep '^service-account:' "$tmp" | awk -F: '{print $2}' | tr -d ' "')
    export APIKEY=$(grep '^api-key:' "$tmp" | awk -F: '{print $2}' | tr -d ' "')
    export APPLY
    APPLY="$(yaml_apply "$tmp")"
    if [[ "$APPLY" != "managed" && "$APPLY" != "ignore" && "$APPLY" != "once" ]]; then
      rm -f "$tmp"
      echo "ERROR: apply debe ser managed, ignore o once (o omitirse). $stmt: apply=$APPLY" >&2
      exit 1
    fi
    if [[ -n "${STOP_STATEMENT_NAME:-}" && "${STATEMENT_NAME}" == "${STOP_STATEMENT_NAME}" && "${stmts_path}" == "${YAML_FILES_DML_PATH}" ]]; then
      if [[ "${APPLY}" != "managed" ]]; then
        rm -f "$tmp"
        echo "ERROR: stop_statement ${STATEMENT_NAME} debe ser un DML managed (apply=${APPLY})" >&2
        exit 1
      fi
      export STOPPED="true"
      STOP_DML_HIT=1
      echo "... Action: ${STATEMENT_NAME} → stopped=true (solo este DML)"
    fi
    if [[ -n "$only_apply" && "$APPLY" != "$only_apply" ]]; then
      rm -f "$tmp"
      continue
    fi
    if [[ "$APPLY" == "ignore" ]]; then
      echo "... skip $STATEMENT_NAME (apply: ignore) — no se genera resource; si estaba managed, el plan propone destroy"
      echo "# apply: ignore  $STATEMENT_NAME" >> "$tf_stmt_final"
      rm -f "$tmp"
      continue
    fi
    export APIKEY_KEY=$(get_value_from_input "$flink_credentials" "$PRINCIPAL/$APIKEY" "key")
    export APIKEY_SECRET=$(get_value_from_input "$flink_credentials" "$PRINCIPAL/$APIKEY" "secret")
    export STATEMENT="$(awk '
    /^statement:[[:space:]]*\|[[:space:]]*$/ {inblock=1; next}
    inblock && /^[^[:space:]]/ {exit}
    inblock {
      sub(/^  /,"")
      print
    }
    ' "$tmp")"
    STATEMENT="${STATEMENT//\$\{catalog_name\}/${CATALOG_NAME}}"
    STATEMENT="${STATEMENT//\$\{cluster_name\}/${CLUSTER_NAME}}"
    export STATEMENT
    export PROPERTIES_BLOCK
    PROPERTIES_BLOCK="$(yaml_properties_hcl "$tmp")"
    echo "STATEMENT_NAME: $STATEMENT_NAME"
    echo "COMPUTE_POOL: $COMPUTE_POOL"
    echo "APIKEY_KEY: $APIKEY_KEY"
    #echo "APIKEY_SECRET: $APIKEY_SECRET"
    #Validate
    require_var $COMPUTE_POOL "no se encontró flink-compute-pool en $stmt"
    require_var $APIKEY_KEY "Sin credenciales para: $PRINCIPAL/$APIKEY"
    require_var $APIKEY_SECRET "Sin credenciales para: $PRINCIPAL/$APIKEY"
    #push --> file
      echo "is_resultado_yaml_ddl= $is_resultado_yaml_ddl"
    if [  $is_resultado_yaml_ddl == true ] ; then
      echo "********* Credentials DDL ********* "
      export VAR_FLINK_APIKEY="key    = \"${VAR_confluent_flink_api_key}\""
      export VAR_FLINK_APISECRET="secret = \"${VAR_confluent_flink_api_secret}\""
    else
      echo "********* Credentials DML ********* "
      export VAR_FLINK_APIKEY="key    = \"$APIKEY_KEY\""
      export VAR_FLINK_APISECRET="secret = \"${APIKEY_SECRET}\""
    fi

    if [[ "$APPLY" == "once" ]]; then
      export ONCE_API_KEY="$APIKEY_KEY"
      export ONCE_API_SECRET="$APIKEY_SECRET"
      if [[ "${is_resultado_yaml_ddl}" == "true" ]]; then
        export ONCE_API_KEY="${VAR_confluent_flink_api_key:-}"
        export ONCE_API_SECRET="${VAR_confluent_flink_api_secret:-}"
      fi
      echo "... apply: once → terraform_data.once_${STATEMENT_NAME}"
      cat <<EOF >> "$tf_stmt_final"
$(envsubst < "${AUTOMATION_DIRNAME}/template/stmt_flink_once.tf.tpl")
EOF
    else
      cat <<EOF >> "$tf_stmt_final"
$(envsubst < $tpl_stmt)
EOF
    fi
    #load CPS-file $LIST_CPS_PATH
    echo $COMPUTE_POOL >> $list_cps

  if ! grep -q "sa_${PRINCIPAL}" "$ARCHIVO_TF_SA"; then
    #
    echo "...(data sa) Principal: $PRINCIPAL"
    echo "... INI LOAD DATA SA **stmt**"
    cat <<EOF >> "$ARCHIVO_TF_SA"
$(envsubst < $ARCHIVO_TPL_SA)
EOF
    echo "... FIN LOAD DATA SA **stmt**"
  fi

    rm -f "$tmp"
  done
}
#Valida path ddl/dml
validate_path_yamls() {
  local input="$1"
  resultado=false
  if [[ -d "$input" ]]; then
    num_file=$(find "$input" -maxdepth 1 -type f -name '*.yaml' | wc -l)
    if [[ "$num_file" -eq 0 ]]; then
      resultado=false
    else
      resultado=true
    fi    
  fi
  echo $resultado
}
#
########## FIN - FUNCTIONS ##########
#
#
#
echo "INI - LOAD STATEMENTS, CPS"
#
##### FILE RESOURCES STMTS #####
ARCHIVO_TPL_STMTS="${AUTOMATION_DIRNAME}/template/stmt_flink.tf.tpl"
ARCHIVO_TF_STMTS_ALL=$(basename "${ARCHIVO_TPL_STMTS%.*}")
rm -f $ARCHIVO_TF_STMTS_ALL
touch $ARCHIVO_TF_STMTS_ALL
##### CPS LIST #####
LIST_CPS_PATH="./local_data_cp.txt"
rm -f $LIST_CPS_PATH
touch $LIST_CPS_PATH
##### FILE DATA CPS #####
ARCHIVO_DATA_TPL_CP="${AUTOMATION_DIRNAME}/template/data_cp_flink.tf.tpl"
ARCHIVO_DATA_TF_CP=$(basename "${ARCHIVO_DATA_TPL_CP%.*}")
rm -f $ARCHIVO_DATA_TF_CP
touch $ARCHIVO_DATA_TF_CP
#
#
#
#
#ARCHIVO_TPL_SA="${AUTOMATION_DIRNAME}/template/data_sa_flink.tf.tpl"
#NAME_ARCHIVO_TF_SA=$(basename "${ARCHIVO_TPL_SA%.*}")
#ARCHIVO_TF_SA="$RELATIVE_SUBPATH_TERRAFORM/$NAME_ARCHIVO_TF_SA"
#echo "ARCHIVO_TF_SA   : ${ARCHIVO_TF_SA}"

ARCHIVO_TPL_SA="${AUTOMATION_DIRNAME}/template/data_sa_flink.tf.tpl"
ARCHIVO_TF_SA=$(basename "${ARCHIVO_TPL_SA%.*}")
# No pisar los SA que acaba de escribir gen_rbac en el stack.
if [[ -f "${RELATIVE_SUBPATH_TERRAFORM}/${ARCHIVO_TF_SA}" ]]; then
  cp "${RELATIVE_SUBPATH_TERRAFORM}/${ARCHIVO_TF_SA}" "${ARCHIVO_TF_SA}"
else
  rm -f "${ARCHIVO_TF_SA}"
  touch "${ARCHIVO_TF_SA}"
fi
echo "ARCHIVO_TF_SA   : ${ARCHIVO_TF_SA}"

#
#
#

echo "... Load depends_on__rbac_resources to DDLs"
ARCHIVO_TPL_RBAC="${AUTOMATION_DIRNAME}/template/rbac_flink.tf.tpl"
ARCHIVO_TF_RBAC=$(basename "${ARCHIVO_TPL_RBAC%.*}")
ARCHIVO_TF_RBAC_FULL=$RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_RBAC
#
export DEPENDS_ON_BLOCK=""
depends_on__rbacs_block=""
if [[ -f "$ARCHIVO_TF_RBAC_FULL" ]]; then
  depends_on__rbac_resources=$(grep -E '^resource "confluent_role_binding"' $ARCHIVO_TF_RBAC_FULL | awk -F'"' '{print $2"."$4}')
  depends_on__rbacs_block=$(echo "$depends_on__rbac_resources" | awk '{print "  "$0}' | awk 'NR>1{printf ",\n"}{printf "%s", $0}')
  export DEPENDS_ON_BLOCK="$depends_on__rbacs_block"
fi
export is_resultado_yaml_ddl=$(validate_path_yamls $YAML_FILES_DDL_PATH)
if [[ $is_resultado_yaml_ddl == true ]]; then
  echo "... ... Procesar DDLs with $DEPENDS_ON_BLOCK"
  load_file_stmts_all "$YAML_FILES_DDL_PATH" "$TF_VAR_flink_credentials" "$ARCHIVO_TF_STMTS_ALL" "$ARCHIVO_TPL_STMTS" "$LIST_CPS_PATH"
else
  echo "... Warning DDL: path o yamls no existen en $YAML_FILES_DDL_PATH. Pasa a DML"
fi
#
#
#
export is_resultado_yaml_ddl=false

echo "... Load depends_on rbcas y ddl, to DMLs"
depends_on__stmts_block=""
if [[ -s "$ARCHIVO_TF_STMTS_ALL" ]]; then
  depends_on__stmts_ddl_resources=$(grep -E '^resource "(confluent_flink_statement|terraform_data)"' $ARCHIVO_TF_STMTS_ALL | awk -F'"' '{print $2"."$4}')
  depends_on__stmts_block=$(echo "$depends_on__stmts_ddl_resources" | awk '{print "  "$0}' | awk 'NR>1{printf ",\n"}{printf "%s", $0}')
  export DEPENDS_ON_BLOCK="$depends_on__stmts_block"
  if [[ -f "$ARCHIVO_TF_RBAC_FULL" ]]; then
    export DEPENDS_ON_BLOCK="$depends_on__stmts_block,$depends_on__rbacs_block"
  fi
fi
#
resultado=$(validate_path_yamls $YAML_FILES_DML_PATH)
STOP_DML_HIT=0
if [[ $resultado == true ]]; then
  echo "... ... Procesar DMLs with $DEPENDS_ON_BLOCK"
  load_file_stmts_all "$YAML_FILES_DML_PATH" "$TF_VAR_flink_credentials" "$ARCHIVO_TF_STMTS_ALL" "$ARCHIVO_TPL_STMTS" "$LIST_CPS_PATH"
else
  echo "... Warning DML: path o yamls no existen en $YAML_FILES_DML_PATH. Fin."
fi
if [[ -n "${STOP_STATEMENT_NAME:-}" && "${STOP_DML_HIT}" -ne 1 ]]; then
  echo "ERROR: stop_statement '${STOP_STATEMENT_NAME}' no coincide con ningún DML managed de ${YAML_FILES_DML_PATH}" >&2
  exit 1
fi
#
echo "FIN - LOAD STATEMENTS, CPS"
#
#
#
echo "...INI - LOAD DATA COMPUTE-POOL"
echo "...$LIST_CPS_PATH: $(cat $LIST_CPS_PATH)"
cat $LIST_CPS_PATH | sort -u | while IFS=$'\t' read -r cp; do
  export COMPUTE_POOL="$cp"
  cat <<EOF >> "$ARCHIVO_DATA_TF_CP"
$(envsubst < $ARCHIVO_DATA_TPL_CP)
EOF
  done
mv $ARCHIVO_DATA_TF_CP $RELATIVE_SUBPATH_TERRAFORM
mv $ARCHIVO_TF_STMTS_ALL $RELATIVE_SUBPATH_TERRAFORM
rm -f "$LIST_CPS_PATH"

#
#echo "********** contenido de archivo: $ARCHIVO_TF_SA *******"
#cat $ARCHIVO_TF_SA
echo "********** contenido de archivo: $ARCHIVO_TF_SA *******"
mv $ARCHIVO_TF_SA $RELATIVE_SUBPATH_TERRAFORM
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_SA
#
echo "********** contenido de archivo: $ARCHIVO_DATA_TF_CP *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_DATA_TF_CP
echo "********** contenido de archivo: $ARCHIVO_TF_STMTS_ALL *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_STMTS_ALL
#
echo "FIN - LOAD STATEMENTS, CPS"
