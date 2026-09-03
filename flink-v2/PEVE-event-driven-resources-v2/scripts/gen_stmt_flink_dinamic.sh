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
load_file_stmts_all(){
  local stmts_path=$1
  local flink_credentials=$2
  local tf_stmt_final=$3
  local tpl_stmt=$4
  local list_cps=$5
  #
  for stmt in "$stmts_path"/*.yaml; do
    sed "s/\${environment}/${ENVIRONMENT}/g" $stmt > $stmt.with.environment
    export STATEMENT_NAME=$(grep '^statement-name:' "$stmt.with.environment" | awk -F: '{print $2}' | tr -d ' "')
    export COMPUTE_POOL=$(grep '^flink-compute-pool:' "$stmt.with.environment" | awk -F: '{print $2}' | tr -d ' "')
    export STOPPED=$(grep '^stopped:' "$stmt.with.environment" | awk -F: '{print $2}' | tr -d ' "')
    export PRINCIPAL=$(grep '^service-account:' "$stmt.with.environment" | awk -F: '{print $2}' | tr -d ' "')
    export APIKEY=$(grep '^api-key:' "$stmt.with.environment" | awk -F: '{print $2}' | tr -d ' "')
    export APIKEY_KEY=$(get_value_from_input "$flink_credentials" "$PRINCIPAL/$APIKEY" "key")
    export APIKEY_SECRET=$(get_value_from_input "$flink_credentials" "$PRINCIPAL/$APIKEY" "secret")
    export STATEMENT="$(awk '
    /^statement:[[:space:]]*\|[[:space:]]*$/ {inblock=1; next}
    inblock && /^[^[:space:]]/ {exit}
    inblock {
      sub(/^  /,"")
      print
    }
    ' "$stmt.with.environment")"
    echo "STATEMENT_NAME: $STATEMENT_NAME"
    echo "COMPUTE_POOL: $COMPUTE_POOL"
    echo "APIKEY_KEY: $APIKEY_KEY"
    echo "APIKEY_SECRET: $APIKEY_SECRET"
    #Validate
    require_var $COMPUTE_POOL "no se encontró flink-compute-pool en $stmt"
    require_var $APIKEY_KEY "Sin credenciales para: $PRINCIPAL/$APIKEY"
    require_var $APIKEY_SECRET "Sin credenciales para: $PRINCIPAL/$APIKEY"
    #push --> file
    cat <<EOF >> "$tf_stmt_final"
$(envsubst < $tpl_stmt)
EOF
    #load CPS-file $LIST_CPS_PATH
    echo $COMPUTE_POOL >> $list_cps
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
resultado=$(validate_path_yamls $YAML_FILES_DDL_PATH)
if [ $resultado == true ] ; then
  echo "... ... Procesar DDLs with $DEPENDS_ON_BLOCK"
  load_file_stmts_all "$YAML_FILES_DDL_PATH" "$TF_VAR_flink_credentials" "$ARCHIVO_TF_STMTS_ALL" "$ARCHIVO_TPL_STMTS" "$LIST_CPS_PATH"
else 
  echo "... Warning DDL: path o yamls no exiten en $YAML_FILES_DDL_PATH. Pasa a DML"
fi
#
#
#
echo "... Load depends_on rbcas y ddl, to DMLs"
depends_on__stmts_block=""
if [[ -s "$ARCHIVO_TF_STMTS_ALL" ]]; then
  depends_on__stmts_ddl_resources=$(grep -E '^resource "confluent_flink_statement"' $ARCHIVO_TF_STMTS_ALL | awk -F'"' '{print $2"."$4}')
  depends_on__stmts_block=$(echo "$depends_on__stmts_ddl_resources" | awk '{print "  "$0}' | awk 'NR>1{printf ",\n"}{printf "%s", $0}')
  export DEPENDS_ON_BLOCK="$depends_on__stmts_block"
  if [[ -f "$ARCHIVO_TF_RBAC_FULL" ]]; then
    export DEPENDS_ON_BLOCK="$depends_on__stmts_block,$depends_on__rbacs_block"
  fi
fi
#
resultado=$(validate_path_yamls $YAML_FILES_DML_PATH)
if [ $resultado == true ] ; then
  echo "... ... Procesar DMLs with $DEPENDS_ON_BLOCK"
  load_file_stmts_all "$YAML_FILES_DML_PATH" "$TF_VAR_flink_credentials" "$ARCHIVO_TF_STMTS_ALL" "$ARCHIVO_TPL_STMTS" "$LIST_CPS_PATH" 
else
  echo "... Warning DML: path o yamls no exiten en $YAML_FILES_DML_PATH. Fin."
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
#
echo "********** contenido de archivo: $ARCHIVO_DATA_TF_CP *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_DATA_TF_CP
echo "********** contenido de archivo: $ARCHIVO_TF_STMTS_ALL *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_STMTS_ALL
#
echo "FIN - LOAD STATEMENTS, CPS"
