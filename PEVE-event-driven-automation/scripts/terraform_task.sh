#!/bin/bash
set -euo pipefail
source ./scripts/terraform_custom_plan_guard.sh

eda_resource_script (){
    JOB_STAGE="$1"

#	IS_ALLOW_REPLACE="${2:-false}"
	IS_ALLOW_REPLACE=${IS_ALLOW_REPLACE}
	if [[ -z "$IS_ALLOW_REPLACE" || "$IS_ALLOW_REPLACE" == "null" || "$IS_ALLOW_REPLACE" == "empty" ]]; then
		IS_ALLOW_REPLACE="false"
	fi

	ALLOW_REPLACE=""
	if [[ "$IS_ALLOW_REPLACE" == "true" ]]; then
		ALLOW_REPLACE="--allow-replace"
	fi
	
	export STRICT_VALIDATE_ALLOW_ONLY_DELETE=${STRICT_VALIDATE_ALLOW_ONLY_DELETE_RESOURCE:-false}

	rm -f /tmp/tf_output.txt

#	yq --version
	mkdir -p "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/topics"
	mkdir -p "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/security"
	
#	pwd
	  AMBIENTE=$(echo "${ENV}" | cut -c1-3 | tr '[:upper:]' '[:lower:]')
	  echo "************************************** APROVISIONAMIENTO($AMBIENTE): $SPECIFIC_RESOURCES ***************************************** "

	if [ "$SPECIFIC_RESOURCES" == "RBAC" ]; then
	  files=$(ls "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/security"/cc-*-rbac-$AMBIENTE.yaml 2>/dev/null || echo "")
	  if [ -z "$files" ]; then
		echo "pwd: ${NAME_DIR_APP}/${ENV}/security/" 2>&1 | tee -a /tmp/tf_output.txt
		echo "No se encontraron archivos que coincidan con el patrón './security/cc-*-rbac-$AMBIENTE.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
		exit 0
	  fi
	else
	  files=$(ls "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/topics"/cc-*-topics.yaml 2>/dev/null || echo "")
	  if [ -z "$files" ]; then
		echo "pwd: ${NAME_DIR_APP}/${ENV}/topics/" 2>&1 | tee -a /tmp/tf_output.txt
		echo "No se encontraron archivos que coincidan con el patrón './topics/cc-*-topics.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
		exit 0
	  fi
	fi



	
	export ARM_ACCESS_KEY=$( echo $HV_PEVE_SECRETS |jq -r '.PEVE_GHA_ARM_ACCESS_KEY')

	for file in $files; do

	  echo "*                                             "
	  echo "*                                             "

	  if [ "$SPECIFIC_RESOURCES" == "RBAC" ]; then
		echo " _____   ____      _       _____  "
		echo "|  __ \ |  _ \    / \     / ____| "
		echo "| |__) || |_) |  / _ \   | |      "
		echo "|  _  / |  _ <  / |_) \  | |      "
		echo "| | \ \ | |_) |/  ___  \ | |____  "
		echo "|_|  \_\|____//__/   \__\ \_____| "
		echo "*                                "
	  else
		echo " _______   ____   _____   _   _____   _____  "
		echo "|__   __| / __ \ |  __ \ | | / ____| / ____| "
		echo "   | |   | |  | || |__) || || |     | (___   "
		echo "   | |   | |  | ||  ___/ | || |      \___ \  "
		echo "   | |   | |__| || |     | || |____  ____) | "
		echo "   |_|    \____/ |_|     |_| \_____||_____/  "
		echo "*                                            "
	  fi

	  echo "*                                            "
      echo "      INICIO JOB                             "
 	  echo "*                                            "
	  
	  echo ""
	  echo ""
	  echo ""
	  echo "********************************************************************************************************************************* "

	  content=$(cat $file)
	  properties_name=$(echo "$content" | yq '.cluster.cc.properties[0].name')
#	  echo "$properties_name"
	  echo "${CC_PROPERTIES}" > cc_properties.json
	  #echo "Imprimir contenido del archivo cc_properties.json"
	  #echo "validar JSON cc_properties.json"

	  #Imprimir en pantalla y Validar que el contenido sea JSON
	  #cat cc_properties.json | jq .
	  #Validar que el contenido sea JSON
	  echo "Validar JSON cc_properties.json"
	  cat cc_properties.json | jq . > /dev/null 2>&1

	  cluster_id=$(jq -r ".${properties_name}.cluster_id" cc_properties.json)
	  environment_id=$(jq -r ".${properties_name}.environment_id" cc_properties.json)
	  organization_id=$(jq -r ".${properties_name}.organization_id" cc_properties.json)
	  cluster_endpoint=$(jq -r ".${properties_name}.cluster_endpoint" cc_properties.json)
	  sr_properties=$(jq -r ".${properties_name}.sr_properties" cc_properties.json)


	  export baseFilename=$(basename "$file")
	  echo "baseFilename: $baseFilename"

#	  ls -lia ./automation
	  rm -f ./automation/topics.tf
	  rm -f ./automation/rbac.tf
	  rm -f ./automation/data_sa.tf
	  rm -f ./automation/schema_registry.tf
	  rm -f ./automation/schema_registry_mode.tf
	  rm -f ./automation/confluent_subject_config.tf

	  if [ "$SPECIFIC_RESOURCES" == "RBAC" ]; then
		export TS_STATE_NAME="tf-${properties_name}-rbac.tfstate"

		export global_hv_key=$(jq -r ".${properties_name}.global_hv_key" cc_properties.json)

		echo "Obtener API KEY tipo Cloud resource management para Crear RBAC - Properties: .${global_hv_key}"
		export CONFLUENT_CLOUD_API_KEY=$( echo $HV_PEVE_SECRETS |jq -r ".${global_hv_key}_api_key")
		export CONFLUENT_CLOUD_API_SECRET=$( echo $HV_PEVE_SECRETS |jq -r ".${global_hv_key}_api_secret")

		echo "TS_STATE_NAME - RBAC: $TS_STATE_NAME"

#		chmod +x ./automation/scripts/generate_rbac_dinamic.sh
		chmod +x ./scripts/generate_rbac_dinamic.sh
		./scripts/generate_rbac_dinamic.sh "${NAME_DIR_APP}" "${RELATIVE_SUBPATH_SRC}" "$baseFilename" "${ENV}"

	  else
#		chmod +x ./automation/scripts/gen_topic_dinamic.sh
		chmod +x ./scripts/generate_topic_dinamic.sh
		./scripts/generate_topic_dinamic.sh "${NAME_DIR_APP}" "${RELATIVE_SUBPATH_SRC}" "$baseFilename" "${ENV}"

		export TS_STATE_NAME="tf-${properties_name}.tfstate"
		echo "TS_STATE_NAME: $TS_STATE_NAME"
	  fi


	  echo "Obtener el SR API KEY SECRET PARA CLUSTER KAFKA - Properties: .${properties_name}"
	  kafka_api_key=$( echo $HV_PEVE_SECRETS |jq -r ".${properties_name}_api_key")
	  kafka_api_secret=$( echo $HV_PEVE_SECRETS |jq -r ".${properties_name}_api_secret")

	  echo "Obtener API KEY SCHEMA REGISTRY"
	  echo "${CC_SR_PROPERTIES}" > cc_sr_properties.json
	  #echo "Imprimir contenido del archivo cc_sr_properties.json"
	  #cat cc_sr_properties.json

	  echo "validar JSON properties Schema Registry cc_sr_properties.json"
	  cat cc_sr_properties.json | jq . > /dev/null 2>&1

	  schema_registry_id=$(jq -r ".${sr_properties}.schema_registry_id" cc_sr_properties.json)
	  schema_registry_rest_endpoint=$(jq -r ".${sr_properties}.schema_registry_rest_endpoint" cc_sr_properties.json)

	  echo "Obtener el SR API KEY SECRET SCHEMA REGISTRY - Properties: .${sr_properties}"
	  schema_registry_api_key=$( echo $HV_PEVE_SECRETS |jq -r ".${sr_properties}_api_key")
	  schema_registry_api_secret=$( echo $HV_PEVE_SECRETS |jq -r ".${sr_properties}_api_secret")

	  export TF_VAR_cluster_id=$cluster_id
	  export TF_VAR_environment_id=$environment_id
	  export TF_VAR_organization_id=$organization_id
	  export TF_VAR_mds_host=$cluster_endpoint
	  export TF_VAR_sr_id=$schema_registry_id
	  export TF_VAR_sr_rest_endpoint=$schema_registry_rest_endpoint
	  export TF_VAR_sr_api_key=$schema_registry_api_key
	  export TF_VAR_sr_api_secret=$schema_registry_api_secret
	  export TF_VAR_mds_username=$kafka_api_key
	  export TF_VAR_mds_password=$kafka_api_secret

	  echo "Archivo: $file"
	  echo "properties_name: $properties_name"
	  echo "cluster_id: $TF_VAR_cluster_id"
	  echo "environment_id: $TF_VAR_environment_id"
#	  echo "organization_id: $TF_VAR_organization_id"
	  echo "cluster_endpoint: $cluster_endpoint"
	  echo "schema_registry_id: $schema_registry_id"
	  echo "schema_registry_rest_endpoint: $schema_registry_rest_endpoint"
#	  echo "kafka_api_key: $kafka_api_key"

#	  pwd
	  rm -f ./automation/backend.hcl
	  rm -f ./automation/.terraform.lock.hcl
	  rm -rf ./automation/.terraform

	  ENV_PATH_TF=$(echo "${ENV}" | tr '[:lower:]' '[:upper:]')

cat <<EOF > ./automation/backend.hcl
storage_account_name   = "${STORAGE_ACCOUNT_NAME}"
container_name         = "tf-peve-resources"
key                    = "${ENV_PATH_TF}/${NAME_DIR_APP}/${CLUSTER_TYPE}/${TS_STATE_NAME}"
EOF
    #ls -lia ./automation
    #cat ./automation/backend.hcl
    terraform -chdir=./automation init -backend-config=backend.hcl 
    terraform -chdir=./automation validate

    if [[ "$JOB_STAGE" == "apply" ]]; then
        echo "**********************  CD  **********************"
        terraform -chdir=./automation apply --auto-approve -lock-timeout=10m
        terraform -chdir=./automation output -no-color > /tmp/tf_output.txt
    elif [[ "$JOB_STAGE" == "plan" ]]; then
		echo "run: terraform_custom_plan --chdir=./automation $ALLOW_REPLACE"
		terraform_custom_plan --chdir=./automation $ALLOW_REPLACE
    fi

done

	  echo ""
	  echo ""
	  echo ""
	  echo "********************************************************************************************************************************* "

}


eda_resource_terraform_plan (){
    eda_resource_script "plan" "$@"
}
eda_resource_terraform_apply (){
    eda_resource_script "apply" "$@"
}



#PARA AVRO
eda_schemaregistry_terraform_plan (){
    eda_schemaregistry_script "plan" "$@"
}
eda_schemaregistry_terraform_apply (){
    eda_schemaregistry_script "apply" "$@"
}



#PARA AVRO
eda_schemaregistry_script (){
    JOB_STAGE="$1"

#	IS_ALLOW_REPLACE="${2:-false}"
	IS_ALLOW_REPLACE=${IS_ALLOW_REPLACE}
	if [[ -z "$IS_ALLOW_REPLACE" || "$IS_ALLOW_REPLACE" == "null" || "$IS_ALLOW_REPLACE" == "empty" ]]; then
		IS_ALLOW_REPLACE="false"
	fi

	ALLOW_REPLACE=""
	if [[ "$IS_ALLOW_REPLACE" == "true" ]]; then
		ALLOW_REPLACE="--allow-replace"
	fi

	export STRICT_VALIDATE_ALLOW_ONLY_DELETE=${STRICT_VALIDATE_ALLOW_ONLY_DELETE_RESOURCE:-false}

	rm -f /tmp/tf_output.txt

#	yq --version
	mkdir -p "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/governance"

#	pwd
	files=$(ls "${RELATIVE_SUBPATH_SRC}/${NAME_DIR_APP}/${ENV}/governance/"sr-*-subjects.yaml 2>/dev/null || echo "")
	if [ -z "$files" ]; then
	  echo "pwd: ${NAME_DIR_APP}/${ENV}/governance/" 2>&1 | tee -a /tmp/tf_output.txt
	  echo "No se encontraron archivos que coincidan con el patrón 'sr-*-subjects.yaml'." 2>&1 | tee -a /tmp/tf_output.txt
	  exit 0
	fi
	
	export ARM_ACCESS_KEY=$( echo $HV_PEVE_SECRETS |jq -r '.PEVE_GHA_ARM_ACCESS_KEY')

	  AMBIENTE=$(echo "${ENV}" | cut -c1-3 | tr '[:upper:]' '[:lower:]')
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

#	  ls -lia ./automation
	  echo "pwd: $(pwd)"
	  rm -f ./automation/topics.tf
	  rm -f ./automation/rbac.tf
	  rm -f ./automation/data_sa.tf
	  rm -f ./automation/schema_registry.tf
	  rm -f ./automation/schema_registry_mode.tf
	  rm -f ./automation/confluent_subject_config.tf

	  echo "ls -lia ./automation"
	  ls -lia ./automation

	  chmod +x ./scripts/generate_schema_registry_dinamic.sh
	  ./scripts/generate_schema_registry_dinamic.sh "${NAME_DIR_APP}" "${RELATIVE_SUBPATH_SRC}" "$baseFilename" "${ENV}"

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
	  
	  export TF_VAR_sr_id=$schema_registry_id
	  export TF_VAR_sr_rest_endpoint=$schema_registry_rest_endpoint
	  export TF_VAR_sr_api_key=$schema_registry_api_key
	  export TF_VAR_sr_api_secret=$schema_registry_api_secret

	  echo "Archivo: $file"
	  echo "properties_sr_name: $properties_sr_name"
	  echo "schema_registry_id: $schema_registry_id"
	  echo "schema_registry_rest_endpoint: $schema_registry_rest_endpoint"

#	  pwd
	  rm -f ./automation/backend.hcl
	  rm -f ./automation/.terraform.lock.hcl
	  rm -rf ./automation/.terraform

	  ENV_PATH_TF=$(echo "${ENV}" | tr '[:lower:]' '[:upper:]')

cat <<EOF > ./automation/backend.hcl
storage_account_name   = "${STORAGE_ACCOUNT_NAME}"
container_name         = "tf-peve-resources"
key                    = "${ENV_PATH_TF}/${NAME_DIR_APP}/${CLUSTER_TYPE}/tf-${properties_sr_name}-schemaregistry.tfstate"
EOF
	#ls -lia ./automation
	#cat ./automation/backend.hcl
	terraform -chdir=./automation init -backend-config=backend.hcl 
	terraform -chdir=./automation validate

#	if [[ "$IS_ALLOW_REPLACE" == "true" && "$STRICT_VALIDATE_ALLOW_ONLY_DELETE" == "true" ]]; then
	if [[ "$IS_ALLOW_REPLACE" == "true" && ${JOB_STAGE} == "apply" ]]; then
		for r in $(terraform -chdir=./automation state list | grep '^confluent_subject_mode\.'); do
			echo "Removing from state: $r"
			terraform -chdir=./automation state rm "$r"
		done
	fi

	if [[ ${JOB_STAGE} == "apply" ]]; then
		echo "**********************  CD  **********************"
		terraform -chdir=./automation apply --auto-approve -lock-timeout=10m
        terraform -chdir=./automation output -no-color > /tmp/tf_output.txt
	elif [[ ${JOB_STAGE} == "plan" ]]; then
		echo "run: terraform_custom_plan --chdir=./automation $ALLOW_REPLACE"
		terraform_custom_plan --chdir=./automation $ALLOW_REPLACE
	fi


done


	  echo ""
	  echo ""
	  echo ""
	  echo "********************************************************************************************************************************* "


}


"$@"

