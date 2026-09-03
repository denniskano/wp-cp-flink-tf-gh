#!/bin/bash
set -euo pipefail

echo "NAME_DIR_APP: ${NAME_DIR_APP}"
echo "AMBIENTE: ${AMBIENTE}"

#Nos ubicamos en el path que contiene el repo base previamente descargado
#tree
cd ./${WORKING_DIR_RESOURCE_PRE_MERGE}

ASYNCAPI_DIRNAME="${AMBIENTE}/asyncapi"
PATH_ASYNCAPI="${NAME_DIR_APP}/${ASYNCAPI_DIRNAME}"

echo "pwd"
pwd

echo "ls -lia $PATH_ASYNCAPI"
if [[ -d "$PATH_ASYNCAPI" ]]; then
  ls -lia $PATH_ASYNCAPI
fi


ALLOW_EVOLVE_SCHEMA="${ALLOW_EVOLVE_SCHEMA:-false}"
# Normaliza "null" o vacío a false
[[ -z "$ALLOW_EVOLVE_SCHEMA" || "$ALLOW_EVOLVE_SCHEMA" == "null" ]] && ALLOW_EVOLVE_SCHEMA=false

echo "ALLOW_EVOLVE_SCHEMA: ${ALLOW_EVOLVE_SCHEMA}"


files=$(ls "${NAME_DIR_APP}/${AMBIENTE}/governance/"sr-*-subjects.yaml 2>/dev/null || echo "")
if [ -z "$files" ]; then
  echo "pwd: ${NAME_DIR_APP}/${AMBIENTE}/governance/" 2>&1 | tee -a /tmp/tf_output.txt
  echo "No se encontraron archivos que coincidan con el patrón 'sr-*-subjects.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
  exit 0
fi


  echo "************************************** APROVISIONAMIENTO($AMBIENTE): SCHEMA REGISTRY ******************************************* "

for file in $files; do
  echo "*                           "
  echo "*                           "
  echo "  _____  _____   "
  echo " / ____||  __ \  "
  echo "| (___  | |__) | "
  echo " \___ \ |  _  /  "
  echo " ____) || | \ \  "
  echo "|_____/ |_|  \_\ "
  echo "*                "
    echo "      INICIO JOB SR         "
  echo "*                           "

  echo ""
  echo ""
  echo ""
  echo "********************************************************************************************************************************* "

  content=$(cat $file)
  properties_sr_name=$(echo "$content" | yq '.environment.schema_registry.properties[0].name')
  
  echo "${CC_SR_PROPERTIES}" > cc_sr_properties.json
  #echo "Imprimir contenido del archivo cc_sr_properties.json"
  #cat cc_sr_properties.json
  echo "validar JSON properties clusters cc_sr_properties.json"
  cat cc_sr_properties.json | jq . > /dev/null 2>&1

  export baseFilename=$(basename "$file")
  echo "baseFilename: $baseFilename"






  if [[ "${properties_sr_name}" == "cfk" ]]; then
    CLUSTER_TYPE="cfk"
    schema_registry_id="${cfk_sr_id}"
    schema_registry_rest_endpoint="${cfk_sr_rest_endpoint}"

    echo "Obtener el SR API KEY SECRET SCHEMA REGISTRY - Properties: .${properties_sr_name}"
    schema_registry_api_key="${cfk_sr_api_key}"
    schema_registry_api_secret=$( echo $HV_PEVE_SECRETS |jq -r '.PEVE_GHA_CFK_MDS_ACCESS_KEY')
  else
    CLUSTER_TYPE="cc"
    schema_registry_id=$(jq -r ".${properties_sr_name}.schema_registry_id" cc_sr_properties.json)
    schema_registry_rest_endpoint=$(jq -r ".${properties_sr_name}.schema_registry_rest_endpoint" cc_sr_properties.json)

    echo "Obtener el SR API KEY SECRET SCHEMA REGISTRY - Properties: .${properties_sr_name}"
    schema_registry_api_key=$( echo $HV_PEVE_SECRETS |jq -r ".${properties_sr_name}_api_key")
    schema_registry_api_secret=$( echo $HV_PEVE_SECRETS |jq -r ".${properties_sr_name}_api_secret")
  fi

  echo "CLUSTER_TYPE: $CLUSTER_TYPE"
  echo "schema_registry_rest_endpoint: $schema_registry_rest_endpoint"
  echo "Archivo: $file"



  echo "----------------------------------------"
  echo "✅ Verificar cambios detectados en: $file"
  echo "----------------------------------------"




count=$(yq '.environment.schema_registry.subjects | length' "$file")

# Recorrer cada índice
for i in $(seq 0 $((count - 1))); do
  export SUBJECT_NAME=$(yq ".environment.schema_registry.subjects[$i].name" "$file")

  if [[ -z "$SUBJECT_NAME" || "$SUBJECT_NAME" == "null" ]]; then
    echo "continue +++"
    continue
  fi
  
  context=$(yq ".environment.schema_registry.subjects[$i].context" "$file")
  
  if [[ -z "$context" || "$context" == "null" || "$context" == "default" ]]; then
    export context=""
  else
    export context=":.$context:"
  fi


  # 1) Tomamos todos los archivos que matchean xxxxx-value-v*.<cualquier_ext>
  shopt -s nullglob
  if [[ ! -d "$PATH_ASYNCAPI" ]]; then
    echo "❌ El directorio NO existe: $PATH_ASYNCAPI"
    avro_files = []
  else
    avro_files=( "$PATH_ASYNCAPI"/"${SUBJECT_NAME}"-v*.* )
  fi
  shopt -u nullglob


  # 2) Contamos las versiones de archivo disponibles
  count_avro_files=${#avro_files[@]}
  echo "Cantidad de archivos AVRO encontrados: $count_avro_files"


  if (( count_avro_files == 0 )); then
    echo "❌ No se encontraron archivos AVRO para el subject $SUBJECT_NAME"
    echo "continue +++"
    continue
  fi


  #Consultamos que existan la misma cantidad de versiones que archivos

  AUTH=(-u "$schema_registry_api_key:$schema_registry_api_secret")

  # Endpoint típico para verificar subject:
  # GET /subjects/{subject}/versions  -> devuelve array de versiones (ej: [1,2,3]) o [] si no hay (raro)
  # Si no existe -> 404
  endpoint="$schema_registry_rest_endpoint/subjects/$SUBJECT_NAME/versions"

  # Ejecuta curl capturando body y status code
  resp="$(curl -sS "${AUTH[@]}" \
    -H "Accept: application/vnd.schemaregistry.v1+json" \
    -w $'\n%{http_code}' \
    "$endpoint" )"

  body="$(printf '%s' "$resp" | sed '$d')"   # todo menos la última línea
  code="$(printf '%s' "$resp" | tail -n1)"   # última línea

  # Normaliza body (sin espacios/CRLF)
  body_min="$(printf '%s' "$body" | tr -d '[:space:]' | tr -d '\r')"
  
  count_versions="$(echo "$body_min" | jq 'length')"
  echo "Total Versiones: $count_versions, body_min: $body_min"

  if [[ "$code" == "200" ]]; then
    if [[ "${ALLOW_EVOLVE_SCHEMA}" == "true" ]]; then
      echo "✅ ($file) Subject $SUBJECT_NAME existe"
      #exit 0
    elif [[ "${ALLOW_EVOLVE_SCHEMA}" == "false" ]] && (( count_versions == count_avro_files )); then
      echo "ℹ️ ($file) Subject $SUBJECT_NAME, Total Archivos: $count_avro_files, Versiones en CC: $body_min"
    else
      echo "❌ ($file) Subject $SUBJECT_NAME existe." 2>&1 | tee -a /tmp/console-out.txt
      exit 1
    fi
  elif [[ "$code" == "404" ]]; then
    if [[ "${ALLOW_EVOLVE_SCHEMA}" == "true" ]]; then
      echo "❌ ($file) Subject NO existe (404): $SUBJECT_NAME" 2>&1 | tee -a /tmp/console-out.txt
      exit 1
    else
      echo "✅ ($file) Subject NO existe (404): $SUBJECT_NAME"
      #exit 0
    fi
  else
    echo "❌ ($file) Error consultando Schema Registry. HTTP=$code" 2>&1 | tee -a /tmp/console-out.txt
    echo "Body: $body" 2>&1 | tee -a /tmp/console-out.txt
    exit 1
  fi





done

















  echo "ℹ️ Validacion de version de esquemas (OK): $file."  2>&1 | tee -a /tmp/console-out.txt

  echo "----------------------------------------"
  echo "✅ Fin."
  echo "----------------------------------------"


done


