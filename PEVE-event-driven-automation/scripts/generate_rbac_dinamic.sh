#!/bin/bash
set -euo pipefail

CODAPP=$1
RELATIVE_SUBPATH_SRC=$2
YAML_FILENAME=$3
ENVIRONMENT=$4

YAML_FILE="${RELATIVE_SUBPATH_SRC}/${CODAPP}/${ENVIRONMENT}/security/${YAML_FILENAME}"

AUTOMATION_DIRNAME="./automation"

#Archivo a generar
ARCHIVO_TPL_RBAC="${AUTOMATION_DIRNAME}/rbac.tf.tpl"
ARCHIVO_TF_RBAC=$(basename "${ARCHIVO_TPL_RBAC%.*}")

ARCHIVO_TPL_SA="${AUTOMATION_DIRNAME}/data_sa.tf.tpl"
ARCHIVO_TF_SA=$(basename "${ARCHIVO_TPL_SA%.*}")


ARCHIVO_TF_RBAC="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_RBAC}"
ARCHIVO_TF_SA="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_SA}"
echo "ARCHIVO_TF_RBAC: ${ARCHIVO_TF_RBAC}"
echo "ARCHIVO_TF_SA: ${ARCHIVO_TF_SA}"



# Limpiar archivo si ya existe
rm -f $ARCHIVO_TF_RBAC
touch $ARCHIVO_TF_RBAC

rm -f $ARCHIVO_TF_SA
touch $ARCHIVO_TF_SA

# Recorre cada entrada en cluster.cc.rbac
rbac_count=$(yq '.cluster.cc.rbac | length' "$YAML_FILE")

for ((i=0; i<rbac_count; i++)); do
  export PRINCIPAL=$(yq ".cluster.cc.rbac[$i].principal" "$YAML_FILE")
  echo "Principal: $PRINCIPAL"
  # Agregar contenido al archivo tf
  cat <<EOF >> "$ARCHIVO_TF_SA"
$(envsubst < $ARCHIVO_TPL_SA)
EOF

  resource_count=$(yq ".cluster.cc.rbac[$i].resources | length" "$YAML_FILE")

  for ((j=0; j<resource_count; j++)); do
    export RESOURCE_TYPE=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_type" "$YAML_FILE")
    export RESOURCE_NAME=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_name" "$YAML_FILE")
    export PATTERN_TYPE=$(yq ".cluster.cc.rbac[$i].resources[$j].pattern_type" "$YAML_FILE")

    export RESOURCE_NAME0=${RESOURCE_NAME//./-}
    if [[ -z "$RESOURCE_NAME" || "$RESOURCE_NAME" == "null" || "$RESOURCE_NAME" == "*" ]]; then

      if [[ "$PATTERN_TYPE" == "PREFIXED" ]]; then
        export RESOURCE_NAME=""
        export RESOURCE_NAME0="ALL"
      fi

    fi

    if [[ "$RESOURCE_TYPE" == "subject" ]]; then
      export RESOURCE_CRN="schema-registry=\${var.sr_id}"
    elif [[ "$RESOURCE_TYPE" == "topic" || "$RESOURCE_TYPE" == "group" || "$RESOURCE_TYPE" == "transactional-id" ]]; then
      export RESOURCE_CRN="cloud-cluster=\${var.cluster_id}/kafka=\${var.cluster_id}"
    elif [[ "$RESOURCE_TYPE" == "compute-pool" ]]; then
      FLINK_REGION=$(yq ".cluster.cc.rbac[$i].resources[$j].resource_region" "$YAML_FILE")
      export RESOURCE_CRN="flink-region=$FLINK_REGION"
    else
      export RESOURCE_CRN="cloud-cluster=${var.cluster_id}"
    fi

    export PATTERN_VALUE=""
    if [[ "$PATTERN_TYPE" == "PREFIXED" ]]; then
      export PATTERN_VALUE="*"
    fi


  #  echo "  Resource Type: $RESOURCE_TYPE"
  #  echo "  Resource Name: $RESOURCE_NAME"
  #  echo "  Pattern Type: $PATTERN_TYPE"

    role_count=$(yq ".cluster.cc.rbac[$i].resources[$j].role | length" "$YAML_FILE")

    for ((k=0; k<role_count; k++)); do
      export OPERATION=$(yq ".cluster.cc.rbac[$i].resources[$j].role[$k].operation" "$YAML_FILE")
  #    echo "    Operation: $OPERATION"

  # Agregar contenido al archivo tf
  cat <<EOF >> "$ARCHIVO_TF_RBAC"
$(envsubst < $ARCHIVO_TPL_RBAC)
EOF



    done
  done

done

echo ""

#echo "********** contenido de archivo: $ARCHIVO_TF_RBAC  *******"
#cat $ARCHIVO_TF_RBAC

#echo "********** contenido de archivo: $ARCHIVO_TF_SA  *******"
#cat $ARCHIVO_TF_SA
