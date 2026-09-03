#!/bin/bash
#set -euo pipefail

NAME_DIR_APP=$1
RELATIVE_SUBPATH_SRC=$2
YAML_FILENAME=$3
ENVIRONMENT=$4

YAML_FILE="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENVIRONMENT}/governance/${YAML_FILENAME}"
#YAML_FILE="${RELATIVE_SUBPATH_SRC}/${CODAPP}/governance/${YAML_FILENAME}"

RELATIVE_BACK_SUBPATH="../${WORKING_DIR_RESOURCE_PRE_MERGE}" #".."
ASYNCAPI_DIRNAME="${ENVIRONMENT}/asyncapi"
AUTOMATION_DIRNAME="./automation"


#Archivo a generar
ARCHIVO_TPL="${AUTOMATION_DIRNAME}/schema_registry.tf.tpl"
ARCHIVO_TF=$(basename "${ARCHIVO_TPL%.*}")
ARCHIVO_TF="${AUTOMATION_DIRNAME}/${ARCHIVO_TF}"

echo "ARCHIVO_TF: ${ARCHIVO_TF}"

#SCHEMA REGISTRY MODE
ARCHIVO_TPL_SCHEMA_MODE="${AUTOMATION_DIRNAME}/schema_registry_mode.tf.tpl"
ARCHIVO_TF_SCHEMA_MODE=$(basename "${ARCHIVO_TPL_SCHEMA_MODE%.*}")
ARCHIVO_TF_SCHEMA_MODE="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_SCHEMA_MODE}"
echo "ARCHIVO_TF_SCHEMA_MODE: ${ARCHIVO_TF_SCHEMA_MODE}"

#SCHEMA SUBJECT CONFIG
ARCHIVO_TPL_SUBJECT_CONFIG="${AUTOMATION_DIRNAME}/confluent_subject_config.tf.tpl"
ARCHIVO_TF_SUBJECT_CONFIG=$(basename "${ARCHIVO_TPL_SUBJECT_CONFIG%.*}")
ARCHIVO_TF_SUBJECT_CONFIG="${AUTOMATION_DIRNAME}/${ARCHIVO_TF_SUBJECT_CONFIG}"
echo "ARCHIVO_TF_SUBJECT_CONFIG: ${ARCHIVO_TF_SUBJECT_CONFIG}"

# Limpiar archivo si ya existe
rm -f $ARCHIVO_TF
touch $ARCHIVO_TF

rm -f $ARCHIVO_TF_SCHEMA_MODE
touch $ARCHIVO_TF_SCHEMA_MODE

rm -f $ARCHIVO_TF_SUBJECT_CONFIG
touch $ARCHIVO_TF_SUBJECT_CONFIG

PATH_ASYNCAPI="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ASYNCAPI_DIRNAME}"

temp_prop_sr_name=$(yq '.environment.schema_registry.properties[0].name' "$YAML_FILE")
echo "temp_prop_sr_name: $temp_prop_sr_name"
# Obtener el número de elementos en el array subjects
count=$(yq '.environment.schema_registry.subjects | length' "$YAML_FILE")

# Recorrer cada índice
for i in $(seq 0 $((count - 1))); do
  export SUBJECT_NAME=$(yq ".environment.schema_registry.subjects[$i].name" "$YAML_FILE")

  if [[ -z "$SUBJECT_NAME" || "$SUBJECT_NAME" == "null" ]]; then
    echo "continue +++"
    continue
  fi
  
  context=$(yq ".environment.schema_registry.subjects[$i].context" "$YAML_FILE")
  export FORMAT=$(yq ".environment.schema_registry.subjects[$i].format" "$YAML_FILE")
  export COMPATIBILITY_MODE=$(yq ".environment.schema_registry.subjects[$i].compatibility_mode" "$YAML_FILE")
  
  if [[ -z "$FORMAT" || "$FORMAT" == "null" ]]; then
    export FORMAT="AVRO"
  fi
  
  if [[ -z "$context" || "$context" == "null" || "$context" == "default" ]]; then
    export context=""
  else
    export context=":.$context:"
  fi


SUBJECT_PREVIOUS_VERSION=""

# 1) Tomamos todos los archivos que matchean xxxxx-value-v*.<cualquier_ext>
avro_files=( "$PATH_ASYNCAPI"/"${SUBJECT_NAME}"-v*.* )
# 2) Ordenar de forma natural (v1, v2, v10, v15...) y cargar a un array
mapfile -t files_sorted < <(printf '%s\n' "${avro_files[@]}" | sort -V)

# 3) Iterar sobre los archivos que coincidan con el patrón
nTotalVersions=0
for archivo in "${files_sorted[@]}"; do

  export archivo=$archivo
	if [ ! -s "$archivo" ]; then
	  echo "El file $archivo NO existe."
	  continue
	fi

  echo "Nombre file: $archivo"

  # Extraer la parte dinámica del nombre (por ejemplo: v1, v2, etc.)
  export VERSION=$(basename "$archivo" | sed "s/^${SUBJECT_NAME}-//" | sed 's/\..*$//')
  #version_with_ext=$(basename "$archivo" | sed "s/^${SUBJECT_NAME}-//")
  export BASE_FILENAME=$(basename "$archivo")
  #echo "BASE_FILENAME: $BASE_FILENAME"
  export SUBPATH_SR="${RELATIVE_BACK_SUBPATH}/${NAME_DIR_APP}/${ASYNCAPI_DIRNAME}/${BASE_FILENAME}"
  #echo "SUBPATH_SR: $SUBPATH_SR"
  if [ -n "$SUBJECT_PREVIOUS_VERSION" ]; then
    export AVRO_PREVIOUS_VERSION="${SUBJECT_PREVIOUS_VERSION},"
  else
    export AVRO_PREVIOUS_VERSION=""
  fi

  if [[ "${temp_prop_sr_name}" != "cfk" ]]; then 
    export SUBJECT_MODE="confluent_subject_mode.${SUBJECT_NAME}-mode,"
  else
    export SUBJECT_MODE=""
  fi

  # echo "VERSION: $VERSION"
  # echo "BASE_FILENAME: $BASE_FILENAME"
  # echo "SUBPATH_SR: $SUBPATH_SR"
  # echo "AVRO_PREVIOUS_VERSION: $AVRO_PREVIOUS_VERSION"
  # echo "SUBJECT_PREVIOUS_VERSION: $SUBJECT_PREVIOUS_VERSION"
  # echo "SUBJECT_MODE: $SUBJECT_MODE"
  # echo "context: $context"
  # echo "SUBJECT_NAME: $SUBJECT_NAME"
  # echo "FORMAT: $FORMAT"
  # echo "nTotalVersions: $nTotalVersions"
  # echo ""
  
  # Agregar contenido al archivo tf
  cat <<EOF >> "$ARCHIVO_TF"
$(envsubst < $ARCHIVO_TPL)
EOF

  SUBJECT_PREVIOUS_VERSION="confluent_schema.${SUBJECT_NAME}-${VERSION}"
  ((nTotalVersions++))
done


if (( nTotalVersions > 0 )) && [[ "${temp_prop_sr_name}" != "cfk" ]]; then

  echo "Nro Total Versiones ($SUBJECT_NAME): $nTotalVersions"
  export OUTPUT_COMPATIBILITY_MODE=""

if [[ ! ( -z "$COMPATIBILITY_MODE" || "$COMPATIBILITY_MODE" == "null" ) ]]; then
  export OUTPUT_COMPATIBILITY_MODE="compatibility_level = confluent_subject_config.${SUBJECT_NAME}-config.compatibility_level"

  cat <<EOF >> "$ARCHIVO_TF_SUBJECT_CONFIG"
$(envsubst < $ARCHIVO_TPL_SUBJECT_CONFIG)
EOF

fi


  # Agregar contenido al ARCHIVO_TF_SCHEMA_MODE
  cat <<EOF >> "$ARCHIVO_TF_SCHEMA_MODE"
$(envsubst < $ARCHIVO_TPL_SCHEMA_MODE)
EOF


fi

done



echo ""
echo "********** contenido de archivo: $ARCHIVO_TF  *******"
cat $ARCHIVO_TF

echo "********** contenido de archivo: $ARCHIVO_TF_SCHEMA_MODE  *******"
cat $ARCHIVO_TF_SCHEMA_MODE

echo "********** contenido de archivo: $ARCHIVO_TF_SUBJECT_CONFIG  *******"
cat $ARCHIVO_TF_SUBJECT_CONFIG


