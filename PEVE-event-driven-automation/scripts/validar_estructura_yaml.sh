#!/bin/bash
set -euo pipefail
#source ./scripts/validate_yaml/validate_topics.sh

#if [[ "$f" ==  ]]; then
#"$FindPath/security/cc-azure_eu2_kafka01-rbac-$SECURITY_ENV.yaml" ]]; then
#"$FindPath/governance/sr-cfk-subjects.yaml" ]]; then


validar_topicos(){

  if [[ -z "${NAME_DIR_APP:-}" || "$NAME_DIR_APP" == "null" ]]; then
    NAME_DIR_APP="${CODAPP}"
  fi

  echo "NAME_DIR_APP: ${NAME_DIR_APP}"
  echo "AMBIENTE: ${AMBIENTE}"

  BasePath="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${AMBIENTE}"

  if [[ ! -d "$BasePath/topics" ]]; then
    echo "❌ El directorio NO existe: $BasePath/topics"
    exit 0
  fi

  files=$(ls "$BasePath/topics"/cc-*-topics.yaml 2>/dev/null || echo "")
  if [ -z "$files" ]; then
		echo "pwd: ${NAME_DIR_APP}/${AMBIENTE}/topics/" 2>&1 | tee -a /tmp/tf_output.txt
    echo "No se encontraron archivos que coincidan con el patrón './topics/cc-*-topics.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
    exit 0
  fi

  for file in $files; do
    #topics_yaml="$BasePath/topics/cc-azure_eu2_kafka01-topics.yaml"
    topics_yaml="$file"

    if [ -f $topics_yaml ]; then
      echo "Validar topicos: $topics_yaml"
      #validate_topics.sh; validate_topics $topics_yaml
      ./scripts/validate_yaml/validate_topics.sh $topics_yaml
    else 
      echo "No existe: $topics_yaml"
    fi


  done

}



validar_estructura_subjects(){

  if [[ -z "${NAME_DIR_APP:-}" || "$NAME_DIR_APP" == "null" ]]; then
    NAME_DIR_APP="${CODAPP}"
  fi

  echo "NAME_DIR_APP: ${NAME_DIR_APP}"
  echo "AMBIENTE: ${AMBIENTE}"

  BasePath="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${AMBIENTE}"

  if [[ ! -d "$BasePath/governance" ]]; then
    echo "❌ El directorio NO existe: $BasePath/governance"
    exit 0
  fi

  files=$(ls "$BasePath/governance"/sr-*-subjects.yaml 2>/dev/null || echo "")
  if [ -z "$files" ]; then
		echo "pwd: ${NAME_DIR_APP}/${AMBIENTE}/governance/" 2>&1 | tee -a /tmp/tf_output.txt
    echo "No se encontraron archivos que coincidan con el patrón './governance/sr-*-subjects.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
    exit 0
  fi

  for file in $files; do
    subjects_yaml="$file"

    if [ -f $subjects_yaml ]; then
      echo "Validar estructura de esquemas: $subjects_yaml"
      ./scripts/validate_yaml/validate_subjects.sh $subjects_yaml
    else 
      echo "No existe: $subjects_yaml"
    fi


  done

}


validar_estructura_rbac(){

  if [[ -z "${NAME_DIR_APP:-}" || "$NAME_DIR_APP" == "null" ]]; then
    NAME_DIR_APP="${CODAPP}"
  fi

  echo "NAME_DIR_APP: ${NAME_DIR_APP}"
  echo "AMBIENTE: ${AMBIENTE}"

  BasePath="${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${AMBIENTE}"
  if [[ ! -d "$BasePath/security" ]]; then
    echo "❌ El directorio NO existe: $BasePath/security"
    exit 0
  fi

  ENV=$(echo "${AMBIENTE}" | cut -c1-3 | tr '[:upper:]' '[:lower:]')

  files=$(ls "${BasePath}/security"/cc-*-rbac-$ENV.yaml 2>/dev/null || echo "")
  if [ -z "$files" ]; then
		echo "pwd: ${NAME_DIR_APP}/${AMBIENTE}/security/" 2>&1 | tee -a /tmp/tf_output.txt
		echo "No se encontraron archivos que coincidan con el patrón './security/cc-*-rbac-$AMBIENTE.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
    exit 0
  fi

  for file in $files; do
    rbac_yaml="$file"

    if [ -f $rbac_yaml ]; then
      echo "Validar estructura de RBAC: $rbac_yaml"
      ./scripts/validate_yaml/validate_rbac.sh $rbac_yaml
    else 
      echo "No existe: $rbac_yaml"
    fi


  done

}

"$@"

