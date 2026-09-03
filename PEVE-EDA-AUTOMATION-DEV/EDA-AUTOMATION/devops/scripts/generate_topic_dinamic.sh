#!/bin/bash
set -euo pipefail

NAME_DIR_APP=$1
RELATIVE_SUBPATH_SRC=$2
YAML_FILENAME=$3
ENVIRONMENT=$4

YAML_FILE="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENVIRONMENT}/topics/${YAML_FILENAME}"

AUTOMATION_DIRNAME="./automation"

#Archivo a generar
ARCHIVO_TPL_TOPIC="${AUTOMATION_DIRNAME}/topics.tf.tpl"
ARCHIVO_TF_TOPIC=$(basename "${ARCHIVO_TPL_TOPIC%.*}")
ARCHIVO_TF_TOPIC="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_TOPIC}"

echo "ARCHIVO_TF_TOPIC: ${ARCHIVO_TF_TOPIC}"

ARCHIVO_TPL_TOPIC_TAG="${AUTOMATION_DIRNAME}/topics_tag.tf.tpl"
ARCHIVO_TF_TOPIC_TAG=$(basename "${ARCHIVO_TPL_TOPIC_TAG%.*}")
ARCHIVO_TF_TOPIC_TAG="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_TOPIC_TAG}"
echo "ARCHIVO_TF_TOPIC_TAG: ${ARCHIVO_TF_TOPIC_TAG}"


# Limpiar archivo si ya existe
rm -f $ARCHIVO_TF_TOPIC
touch $ARCHIVO_TF_TOPIC

rm -f $ARCHIVO_TF_TOPIC_TAG
touch $ARCHIVO_TF_TOPIC_TAG

# Recorre cada entrada en cluster.cc.topics
topics_count=$(yq '.cluster.cc.topics | length' "$YAML_FILE")

for ((i=0; i<topics_count; i++)); do
  export TOPIC_NAME=$(yq ".cluster.cc.topics[$i].name" "$YAML_FILE")
  export TF_TOPIC_NAME=${TOPIC_NAME//./-}
  #echo "Topic name: $TOPIC_NAME"
  export TOPIC_PARTITIONS=$(yq ".cluster.cc.topics[$i].partitions" "$YAML_FILE")
  #echo "Topic partitions: $TOPIC_PARTITIONS"

  # Extraer el bloque config del primer topic y convertirlo en formato Terraform map(string)
  export TOPIC_CONFIG=$(yq -o=json ".cluster.cc.topics[$i].config" "$YAML_FILE" | jq -r 'to_entries | map("\"\(.key)\" = \"\(.value)\"") | join("\n    ")')
  #echo "MAP CONFIG: $TOPIC_CONFIG"


  METADATA=$(yq ".cluster.cc.topics[$i].metadata" "$YAML_FILE")

  if [[ ! -z "$METADATA" && "$METADATA" != "null" ]]; then

    METADATA_TAGs=$(yq ".cluster.cc.topics[$i].metadata.tags" "$YAML_FILE")
    if [[ ! -z "$METADATA_TAGs" && "$METADATA_TAGs" != "null" ]]; then
      tag_count=$(yq ".cluster.cc.topics[$i].metadata.tags | length" "$YAML_FILE")

      for ((j=0; j<tag_count; j++)); do
        export TAG_NAME=$(yq ".cluster.cc.topics[$i].metadata.tags[$j].name" "$YAML_FILE")
          # Agregar contenido al ARCHIVO_TF_TOPIC_TAG
  cat <<EOF >> "$ARCHIVO_TF_TOPIC_TAG"
$(envsubst < $ARCHIVO_TPL_TOPIC_TAG)
EOF


      done

    fi


  fi


#  yq ".cluster.cc.topics[$i].metadata.properties[]" "$YAML_FILE" | while read -r prop; do
#    echo "    $prop"
#  done

  #config_count=$(yq ".cluster.cc.topics[$i].config | length" "$YAML_FILE")
  #echo "TOTAL CONFIG: $config_count"

  cat <<EOF >> "$ARCHIVO_TF_TOPIC"
$(envsubst < $ARCHIVO_TPL_TOPIC)
EOF

done

echo ""
echo "********** contenido de archivo: $ARCHIVO_TF_TOPIC  *******"
cat $ARCHIVO_TF_TOPIC

echo "********** contenido de archivo: $ARCHIVO_TF_TOPIC_TAG  *******"
cat $ARCHIVO_TF_TOPIC_TAG
