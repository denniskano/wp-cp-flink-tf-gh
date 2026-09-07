@Library('jenkins-sharedlib@atla-new-features')
import sharedlib.JenkinsfileUtil

def utils = new JenkinsfileUtil(steps, this)
/* Project settings */
def project = ""
def namespace = ""
def recipients = ""
def hosted = ""
def aksRG = "''"
def aksCluster = "''"
def subscription = ""
def config_vars = null
def log_monitoring_otel_filebeat = ""
def containerRegistry = ""
def secrets_hv = null
def globals = null
def deployVersion = "2.0.2-RC1"
def deployAtlasVersion = "2.0.3"

try {
  node {
    deploymentEnvironment = params.ENVIRONMENT    
    stage('Preparation') {
      cleanWs()
      checkout scm
      config_vars = readYaml file: "${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      kafkaConnectName = config_vars."kafkaConnectName"
      project=config_vars."project"
      namespace=config_vars."namespace"
      subscription = config_vars."subscription"
      log_monitoring_otel_filebeat=config_vars."log_monitoring_otel_filebeat"
      recipients=config_vars."recipients"
      hosted=config_vars."hosted"
      containerRegistry=config_vars."containerRegistry"
      env.project="${project}"
      utils.notifyByMail('START', recipients)

      utils.prepare()
      utils.setHashicorpVaultEnabled(true)
      utils.setHashicorpVaultEnvironment("${deploymentEnvironment}")
      if ("${deploymentEnvironment}" == "dev" || "${deploymentEnvironment}" == "cert" ) {
        utils.setHashicorpVaultInstance(true)
        if ("${deploymentEnvironment}" == "dev") {
            utils.setHashicorpVaultNamespace("${project}".toLowerCase())
        }
      }

      if (hosted == 'aks'){
        aksRG = config_vars."aksRG"
        aksCluster = config_vars."aksCluster"
      }
    }

    println "Descargando del repo base"
    descargarScriptsPEVE(utils, deploymentEnvironment, deployVersion)
    println "Termino descarga repo peve utils"

    sh "sed -i 's/\${kafkaConnectName}/${kafkaConnectName}/g' ${WORKSPACE}/devops/deploy/global-vars.yaml"
    globals = readYaml file: "${WORKSPACE}/devops/deploy/global-vars.yaml"

    sh "sed -i 's/\${deploymentEnvironment}/${deploymentEnvironment}/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    sh "sed -i 's/\${project}/"+"${project}".toLowerCase()+"/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    sh "sed -i 's/\${namespace}/${namespace}/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    def hosted_on_environment = readYaml file: "${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"

    def DOCKER_SUPPORT_REGISTRY="${containerRegistry}"
    def DOCKER_SUPPORT_REGISTRY_URL="https://${DOCKER_SUPPORT_REGISTRY}"
    def DOCKER_SUPPORT_REGISTRY_CREDENTIAL="acr-devops-${deploymentEnvironment}"
    secrets_hv = config_vars."secrets_hv"

    // Passkey para kafka connect
    def connectCert = config_vars."connectEncryptionKeyHVId";
    utils.withHashicorpVaultCredential([
        [
          vaultCredentialPath: connectCert,
          vaultCredentialType: 'secret-text',
          secret: 'PASSWORD'
        ]
    ]) {
        sh "echo '${PASSWORD}'>>${WORKSPACE}/devops/scripts/passphrase.txt"
    }

    def confluentSecurityMasterKeyName = globals."secrets"."confluentSecurityMasterKey"."secretName"
    stage("Encrypt Secrets") {

      def DOCKER_SUPPORT_IMAGE_JAVA=""

      if(deploymentEnvironment == 'prod') {
        DOCKER_SUPPORT_IMAGE_JAVA="${DOCKER_SUPPORT_REGISTRY}/apsa/kafka-devops-tools:1.0.0"
      }else {
        DOCKER_SUPPORT_IMAGE_JAVA="${DOCKER_SUPPORT_REGISTRY}/atla/kafka-devops-tools:1.0.0"
      }
      def secretFieldsToEncrypt = ""
      secrets_hv.each{key,value ->
        if (value.id != null && value.id.length() > 0 && value.id != ''){
          if(value.type == 'usernamePassword'){
            utils.withHashicorpVaultCredential([
                          [vaultCredentialPath: value.id,
                          vaultCredentialType: 'userpassword',
                          username: 'USERNAME',
                          password: "PASSWORD"]
                        ]) {
              def keyValue1 = value.varkey.split(',')[0] + "='${USERNAME}'"
              def keyValue2 = value.varkey.split(',')[1] + "='${PASSWORD}'"
              sh "echo $keyValue1>>${WORKSPACE}/devops/scripts/plaintext-config-file.properties"
              sh "echo $keyValue2>>${WORKSPACE}/devops/scripts/plaintext-config-file.properties"
            }                        
          } else if(value.type == 'certificate') {
                utils.withHashicorpVaultCredential([
                        [vaultCredentialPath: "internal-certificates/${value.id}",
                        vaultCredentialType: 'certificate',
                        secret: "CERT_PASS",
                        fileValue: 'CERT_FILE',
                        fileExtension: "pfx"]
                        ]) {
                }
          } else if(value.type == 'password' || value.type == 'key') {
                utils.withHashicorpVaultCredential([
                  [vaultCredentialPath: value.id,
                  vaultCredentialType: 'secret-text',
                  secret: 'PASSWORD']
                ]) {
                    def keyValue = value.varkey + "='${PASSWORD}'"
                    sh "echo $keyValue>>${WORKSPACE}/devops/scripts/plaintext-config-file.properties"
                }
          }
          if(secretFieldsToEncrypt == '' && value.varkey != ''){
            secretFieldsToEncrypt = value.varkey
          }else{
            if(value.varkey != null && value.varkey.length() > 0 && value.varkey != ''){
              secretFieldsToEncrypt = secretFieldsToEncrypt+","+value.varkey
            }
          }
        }                    
      }

      sh "chmod +x ${WORKSPACE}/devops/scripts/secret-protection.sh"

      utils.dockerWithRegistryHashicorpVaultAtla(DOCKER_SUPPORT_REGISTRY_CREDENTIAL, DOCKER_SUPPORT_REGISTRY_URL){
        def docker_cmd="docker run --rm -v "
        docker_cmd += " ${WORKSPACE}/devops/scripts/:/opt/security/secrets/:rw "
        docker_cmd += " -u 1002:1014 "
        docker_cmd += " --network host "
        docker_cmd += " -e secretFields=${secretFieldsToEncrypt}"
        def docker_image="${DOCKER_SUPPORT_IMAGE_JAVA}"
        sh "${docker_cmd} ${docker_image} bash /opt/security/secrets/secret-protection.sh /opt/security/secrets"
      }
    }

    stage("Prepare Secrets"){
      def ansible_cmd = "ansible-playbook ${WORKSPACE}/devops/ansible/site_secrets.yaml -v -i ${WORKSPACE}/devops/ansible/hosts.yml "
      def ansible_cmd_common = [
              workspace: "${WORKSPACE}",
              hosted_on: hosted,
              deployment_environment: deploymentEnvironment,
              client_k8s: hosted_on_environment."${hosted}"."client",
              namespace: "${namespace}".toLowerCase(),
              subscription: "${subscription}",
              secretType: 'certificate',
              truststoreName: "${kafkaConnectName}-truststore.jks",
              keystoreName: "${kafkaConnectName}-keystore.jks",
              credentialId: "${kafkaConnectName}",
              kafkaConnectName: "${kafkaConnectName}"
      ]
      for (item in ansible_cmd_common) {
          ansible_cmd+='-e '+item.key+'='+item.value+' '
      }
      deploySecretInCluster(hosted, ansible_cmd,
              hosted_on_environment[hosted].credentials,
              "${DOCKER_SUPPORT_REGISTRY}",
              "${DOCKER_SUPPORT_REGISTRY_URL}",
              "${DOCKER_SUPPORT_REGISTRY_CREDENTIAL}",
              utils,aksRG,aksCluster,deploymentEnvironment,
              "${deployAtlasVersion}")
    }

    stage("Create Secrets") {
      def confluentSecurityMasterKeyFilePath=globals."secrets"."confluentSecurityMasterKey"."filePath"
      def confluentSecretFileEncryptedName=globals."secrets"."confluentSecretFileEncrypted"."secretName"
      def confluentSecretFileEncryptedPath=globals."secrets"."confluentSecretFileEncrypted"."filePath"
      def confluentSecurityMasterKeySecretKey=globals."secrets"."confluentSecurityMasterKey"."secretKey"
      def confluentSecretConfigFileName=globals."secrets"."confluentSecretConfigFile"."secretName"
      def confluentSecretConfigFilePath=globals."secrets"."confluentSecretConfigFile"."filePath"
      def ansible_cmd = "ansible-playbook ${WORKSPACE}/devops/ansible/site_secrets.yaml -v -i ${WORKSPACE}/devops/ansible/hosts.yml "
      def ansible_cmd_common = [
                workspace: "${WORKSPACE}",
                hosted_on: hosted,
                deployment_environment: deploymentEnvironment,
                client_k8s: hosted_on_environment."${hosted}"."client",
                namespace: "${namespace}".toLowerCase(),
                subscription: "${subscription}",
                confluentSecurityMasterKeyName: "${confluentSecurityMasterKeyName}",
                confluentSecretFileEncryptedName: "${confluentSecretFileEncryptedName}",
                confluentSecretFileEncryptedPath:"${confluentSecretFileEncryptedPath}",
                confluentSecurityMasterKeyFilePath:"${confluentSecurityMasterKeyFilePath}",
                confluentSecurityMasterKeySecretKey:"${confluentSecurityMasterKeySecretKey}",
                confluentSecretConfigFileName: "${confluentSecretConfigFileName}",
                confluentSecretConfigFilePath: "${confluentSecretConfigFilePath}",
                kafkaConnectName: "${kafkaConnectName}"
      ]
      for (item in ansible_cmd_common) {
          ansible_cmd+='-e '+item.key+'='+item.value+' '
      }
      deploySecretInCluster(hosted, ansible_cmd,
              hosted_on_environment[hosted].credentials,
              "${DOCKER_SUPPORT_REGISTRY}",
              "${DOCKER_SUPPORT_REGISTRY_URL}",
              "${DOCKER_SUPPORT_REGISTRY_CREDENTIAL}",
              utils,aksRG,aksCluster,deploymentEnvironment,
              "${deployAtlasVersion}")
    }
    utils.prepare()

stage('Start Promote') {
      if ("${deploymentEnvironment}" == "cert")
            utils.startReleaseFreeStyleProject('./devops', 'tar')
    }

  }
} catch(Exception e){
    node{
      utils.executeOnErrorExecutionTasks()
      utils.notifyByMail('FAIL', recipients)
      throw e
    }
}

// ---------------------------------------------------------------------------------

def deploySecretInCluster(hosted, cmd, cred, reghost, regurl, regcred, utils, rg, cluster, deploymentEnvironment, deployAtlasVersion) {

  println "deploying secrets hosted : ${hosted} cmd : ${cmd} with credentials : ${cred}"

  def DOCKER_IP = sh (script: "grep \$(hostname) /etc/hosts | awk '{print \$1}'", returnStdout: true).trim()
  def DOCKER_SUPPORT_IMAGE="${reghost}/atla/atlas-docker-image-deployment-tools:${deployAtlasVersion}"
  def DOCKER_SERVER="tcp://${DOCKER_IP}:2376"

  utils.withHashicorpVaultCredentialAtla(cred, deploymentEnvironment) {
  utils.dockerWithRegistryHashicorpVaultAtla("${regcred}", "${regurl}") {
	  def docker_cmd="docker run --rm -v ${WORKSPACE}:${WORKSPACE}:rw -u 1002:1014 --network host -e DOCKER_HOST=${DOCKER_SERVER} \
		-e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_CONFIG=${WORKSPACE}/devops/ansible/ansible.cfg"
	  def docker_image="${DOCKER_SUPPORT_IMAGE}"
	  def ansible_cmd_extra = [:]
	  if ( hosted == 'aks' ) {
		sh "rm -fr ${WORKSPACE}/tmp; mkdir -p ${WORKSPACE}/tmp; cp AKS_CERTIFICATE ${WORKSPACE}/tmp/AKS_CERTIFICATE"
		ansible_cmd_extra << [
		  aks_cluster: "${cluster}",
		  aks_rg: "${rg}",
		  aks_service_principal: "${AKS_SP}",
		  aks_certificate: "${WORKSPACE}/tmp/AKS_CERTIFICATE",
		  az_tenant: "${AZ_TENANT}",
		  external_registry_username: "''",
		  external_registry_password: "''"
		]
	  } else {
		ansible_cmd_extra << [
		  aks_cluster: "''",
		  aks_rg: "''",
		  az_username: "''",
		  az_password: "''",
		  az_tenant: "''",
		  external_registry_username: "${EXTERNAL_REGISTRY_USERNAME}",
		  external_registry_password: "${EXTERNAL_REGISTRY_PASSWORD}"
		]
	  }
	  for (item in ansible_cmd_extra) {
		  cmd+="-e "+item.key+'='+item.value+' '
	  }
	  sh "${docker_cmd} ${docker_image} ${cmd}"
    }
  }
}

// ---------------------------------------------------------------------------------
def descargarScriptsPEVE(utils, deploymentEnvironment, deployVersion) {

    stage('Download repo Github'){
      def patBCPCloud = "APZW3DES-BCP-GH-Jenkins-DESA"
 
    // Zipear Delivery por ambiente
    def zipENVIRONMENT = (deploymentEnvironment == 'dev')  ? 'develop-deploy.zip' :
                         (deploymentEnvironment == 'cert') ? 'release-deploy.zip' :
                         'master-deploy.zip'

	    withCredentials([
                [
                    $class: 'UsernamePasswordMultiBinding',
                    credentialsId: "${patBCPCloud}",
                    usernameVariable: 'GIT_USERNAME',
                    passwordVariable: 'GIT_PASSWORD'
                ]]) {
        deliveryRepo = "https://api.github.com/repos/BCP-Integration-Automation/PEVE-kafka-connect-base/zipball/${deployVersion}"
    
        sh "curl -s -k -L -H \"Accept: application/vnd.github+json\" \
				   -H \"Authorization: Bearer ${GIT_PASSWORD}\" \
				   -H \"X-GitHub-Api-Version: 2022-11-28\" \
				   -o ${zipENVIRONMENT} ${deliveryRepo}" 

           sh "unzip -o -q ${zipENVIRONMENT} -d tmp-repository"
           sh "cp -r tmp-repository/*/devops/{ansible,scripts} devops"
           sh "cp -r tmp-repository/*/devops/deploy/credentials-hv-map.yaml devops/deploy"
           sh "cp -r tmp-repository/*/devops/deploy/global-vars.yaml devops/deploy"
    }
  }
}
