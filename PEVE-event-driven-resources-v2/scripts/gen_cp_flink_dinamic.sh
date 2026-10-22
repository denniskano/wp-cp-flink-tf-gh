#!/bin/bash
set -euo pipefail
export ENVIRONMENT_ID=$1
echo "ENVIRONMENT_ID: $ENVIRONMENT_ID"
export RELATIVE_SUBPATH_SRC=$2
echo "RELATIVE_SUBPATH_SRC=$RELATIVE_SUBPATH_SRC"
export RELATIVE_SUBPATH_TERRAFORM=$3
echo "RELATIVE_SUBPATH_TERRAFORM:$RELATIVE_SUBPATH_TERRAFORM"
AUTOMATION_DIRNAME="./resources"
echo "AUTOMATION_DIRNAME: $AUTOMATION_DIRNAME"
#
echo "ENVIRONMENT_HV: $ENVIRONMENT_HV"
#VARS_FILE="$ENVIRONMENT_HV-vars.yaml"
VARS_FILE="cc-compute-pools.yaml"
echo "VARS_FILE: $VARS_FILE"
#
YAML_FILE_CPS_FLINK_PATH="${RELATIVE_SUBPATH_SRC}/$VARS_FILE"
echo "YAML_FILE_CPS_FLINK_PATH: $YAML_FILE_CPS_FLINK_PATH"
#
#Valida número de yamls
if [[ ! -f "$YAML_FILE_CPS_FLINK_PATH" ]]; then
  echo "REVISAR: Archivo no existe $YAML_FILE_CPS_FLINK_PATH"
  exit 0
fi
#
ARCHIVO_TPL_CP_FLINK="${AUTOMATION_DIRNAME}/template/cp_flink.tf.tpl"
ARCHIVO_TF_CP_FLINK=$(basename "${ARCHIVO_TPL_CP_FLINK%.*}")
rm -f $ARCHIVO_TF_CP_FLINK
touch $ARCHIVO_TF_CP_FLINK
#
yq -r '.compute_pools[] | [.cloud,.region,.max_cfu,.pool_name] | @tsv' $YAML_FILE_CPS_FLINK_PATH \
| while IFS=$'\t' read -r cloud region max_cfu display_name; do
  export CLOUD="${cloud}"
  export REGION="${region}"  
  export MAX_CFU="${max_cfu}" 
  export DISPLAY_NAME="${display_name}"
  echo "$CLOUD $REGION $MAX_CFU $DISPLAY_NAME"
  cat <<EOF >> "$ARCHIVO_TF_CP_FLINK"
$(envsubst < $ARCHIVO_TPL_CP_FLINK)
EOF
done
#
mv $ARCHIVO_TF_CP_FLINK $RELATIVE_SUBPATH_TERRAFORM
echo ""
echo "********** contenido de archivo: $ARCHIVO_TF_CP_FLINK *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_CP_FLINK
echo "FIN - LOAD STATEMENTS, CPS"
#
##### FIN #####
