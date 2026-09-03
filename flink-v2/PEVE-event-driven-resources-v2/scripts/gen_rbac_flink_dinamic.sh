#!/bin/bash
set -euo pipefail
echo "INI - RBACS"
##### ARGS[] #####
#CODAPP=$1
export ORGANIZATION_ID=$1       #"15995726-1235-4553-a51c-746675ad89e4"
export ENVIRONMENT_ID=$2        #"env-156n66s"
export CLUSTER_ID=$3            #"lkc-xzyppq"  #DESARROLLO"
export SCHEMA_REGISTRY_ID=$4 #"lsrc-9rgmm7"
#$5     #Ruta completa pipeline-nombre-caso-negocio-compras-02
RELATIVE_SUBPATH_SRC=$5         #/mnt/d/Project_GitHub/PEVE-stream-processing-resources-v1/PEVE/ccloud-flink/desa/pipeline-nombre-caso-negocio-compras-02
RELATIVE_SUBPATH_TERRAFORM=$6   #/mnt/d/Utilitarios/Terraform/output
#
#
#
RBACS_YAML_FILE="${RELATIVE_SUBPATH_SRC}"
echo "RBACS_YAML_FILE: $RBACS_YAML_FILE"
AUTOMATION_DIRNAME="./resources"          #"/mnt/d/Project_GitHub/PEVE-event-driven-resources-v2"
echo "AUTOMATION_DIRNAME: $AUTOMATION_DIRNAME"
#
#
#
#FILE RBACS
ARCHIVO_TPL_RBAC="${AUTOMATION_DIRNAME}/template/rbac_flink.tf.tpl"
ARCHIVO_TF_RBAC=$(basename "${ARCHIVO_TPL_RBAC%.*}")
rm -f $ARCHIVO_TF_RBAC  ; touch $ARCHIVO_TF_RBAC
echo "ARCHIVO_TF_RBAC : ${ARCHIVO_TF_RBAC}"
#
ARCHIVO_TPL_SA="${AUTOMATION_DIRNAME}/template/data_sa_flink.tf.tpl"
ARCHIVO_TF_SA=$(basename "${ARCHIVO_TPL_SA%.*}")
rm -f $ARCHIVO_TF_SA    ; touch $ARCHIVO_TF_SA
echo "ARCHIVO_TF_SA   : ${ARCHIVO_TF_SA}"
#
#
#
#Valida numero de yamls
if [[ ! -d "$RBACS_YAML_FILE" ]]; then
  echo "REVISAR: Directorio no existe $RBACS_YAML_FILE"
  exit 0
fi
num_file=$(find "$RBACS_YAML_FILE" -maxdepth 1 -type f -name '*.yaml' | wc -l)
echo "Directorio $RBACS_YAML_FILE: tiene num_file=$num_file"
if [[ "$num_file" -eq 0 ]]; then
  echo "Sin archivos yaml en: $dir"
  exit 0
fi
#
#
# Recorre cada entrada en cluster.cc.rbac
for YAML_FILE in "$RBACS_YAML_FILE"/*.yaml; do
  #
  echo "IN FILE: $YAML_FILE"
  #
  rbac_count=$(yq '.cluster.cc.rbac | length' "$YAML_FILE")
  echo "#principals in file: $rbac_count"
  #  
  for ((i=0; i<rbac_count; i++)); do
    #
    export PRINCIPAL=$(yq ".cluster.cc.rbac[$i].principal" "$YAML_FILE")
    echo "... Principal: $PRINCIPAL"
    echo "... INI LOAD DATA SA"
    cat <<EOF >> "$ARCHIVO_TF_SA"
$(envsubst < $ARCHIVO_TPL_SA)
EOF
    echo "... FIN LOAD DATA SA"
    #
    resource_count=$(yq ".cluster.cc.rbac[$i].resources | length" "$YAML_FILE")
    echo "... Load Resources: $resource_count"
    for ((j=0; j<resource_count; j++)); do
      export RESOURCE_TYPE=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_type" "$YAML_FILE" | awk '{print $1}')
      echo "... ... RESOURCE_TYPE: $RESOURCE_TYPE"
      #
      LOCAL_RESOURCE_NAME=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_name" "$YAML_FILE")
      echo "... ... ... LOCAL_RESOURCE_NAME: $LOCAL_RESOURCE_NAME"
      if [[ "$RESOURCE_TYPE" == "compute-pool" ]]; then
        export RESOURCE_NAME="\${data.confluent_flink_compute_pool.cp_$LOCAL_RESOURCE_NAME.id}"
      else
        export RESOURCE_NAME=$LOCAL_RESOURCE_NAME
      fi
      echo "... ... ... RESOURCE_NAME: $RESOURCE_NAME"
      #
      export PATTERN_TYPE=$(yq ".cluster.cc.rbac[$i].resources[$j].pattern_type" "$YAML_FILE")
      echo "... ... ... PATTERN_TYPE: $PATTERN_TYPE"
      #
      export RESOURCE_NAME0=${LOCAL_RESOURCE_NAME//./-}
      #Evaluar si va ya que todo debe ser LITERAL      
      if [[ -z "$RESOURCE_NAME" || "$RESOURCE_NAME" == "null" || "$RESOURCE_NAME" == "*" ]]; then
        if [[ "$PATTERN_TYPE" == "PREFIXED" ]]; then
          export RESOURCE_NAME=""
          export RESOURCE_NAME0="ALL"
        fi
      fi
      echo "... ... ... RESOURCE_NAME0: $RESOURCE_NAME0"

      if [[ "$RESOURCE_TYPE" == "subject" ]]; then
        export RESOURCE_CRN="/schema-registry=$SCHEMA_REGISTRY_ID/"
      elif [[ "$RESOURCE_TYPE" == "topic" || "$RESOURCE_TYPE" == "group" || "$RESOURCE_TYPE" == "transactional-id" ]]; then
        export RESOURCE_CRN="/cloud-cluster=$CLUSTER_ID/kafka=$CLUSTER_ID/"
      elif [[ "$RESOURCE_TYPE" == "compute-pool" ]]; then
        FLINK_REGION=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_region" "$YAML_FILE")
        echo "FLINK_REGION: $FLINK_REGION"
        export RESOURCE_CRN="/flink-region=$FLINK_REGION/"
      else
        export RESOURCE_CRN="/cloud-cluster=$CLUSTER_ID/"
      fi
      echo "... ... ... RESOURCE_CRN: $RESOURCE_CRN"
      #
      export PATTERN_VALUE=""
      if [[ "$PATTERN_TYPE" == "PREFIXED" ]]; then
        export PATTERN_VALUE="*"
      fi
      echo "... ... ... PATTERN_VALUE: $PATTERN_VALUE"
      #
      role_count=$(yq ".cluster.cc.rbac[$i].resources[$j].role | length" "$YAML_FILE")
      echo "... ... ... ROLES: $role_count"
      for ((k=0; k<role_count; k++)); do
        export OPERATION=$(yq ".cluster.cc.rbac[$i].resources[$j].role[$k].operation" "$YAML_FILE")
        echo "... ... ... ... ... OPERATION: $OPERATION"
        cat <<EOF >> "$ARCHIVO_TF_RBAC"
$(envsubst < $ARCHIVO_TPL_RBAC)
EOF
      done
      echo "... ... ... Fin ROLES"
    done
    echo "... ... ... Fin Resources"
  done
  echo "... Fin Principal"
done
#
mv $ARCHIVO_TF_SA $RELATIVE_SUBPATH_TERRAFORM
mv $ARCHIVO_TF_RBAC $RELATIVE_SUBPATH_TERRAFORM
#
echo "********** contenido de archivo: $ARCHIVO_TF_SA *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_SA
echo "********** contenido de archivo: $ARCHIVO_TF_RBAC *******"
cat $RELATIVE_SUBPATH_TERRAFORM/$ARCHIVO_TF_RBAC
#
echo "FIN - RBACS"
#
#
#
echo "INI - LOAD DATA SR"
properties_name=$CC_SR_PROPERTIES_ID
echo "properties_name: $properties_name"

echo "${CC_SR_PROPERTIES}" > ./cc_sr_properties.json
echo "Imprimir contenido del archivo cc_sr_properties.json"
cat cc_sr_properties.json
tree

sr_properties=$(jq -r ".${properties_name}.sr_properties" cc_sr_properties.json)

schema_registry_id=$(jq -r ".${sr_properties}.schema_registry_id" cc_sr_properties.json)
schema_registry_rest_endpoint=$(jq -r ".${sr_properties}.schema_registry_rest_endpoint" cc_sr_properties.json)
schema_registry_api_key=$( echo $HV_PEVE_SECRETS |jq -r ".${sr_properties}_api_key")
schema_registry_api_secret=$( echo $HV_PEVE_SECRETS |jq -r ".${sr_properties}_api_secret")

export TF_VAR_sr_id=$schema_registry_id
export TF_VAR_sr_rest_endpoint=$schema_registry_rest_endpoint
export TF_VAR_sr_api_key=$schema_registry_api_key
export TF_VAR_sr_api_secret=$schema_registry_api_secret

echo "FIN - LOAD DATA SR"
