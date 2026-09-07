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
def deploymentEnvironment = ""
def subscription = ""
def config_vars = null
def containerRegistry = ""
def transformer_url = ""
def smt_jar_name = ""
def kafkaConnectName = ""
def filebeat = ""
def log_monitoring_otel_filebeat = ""
def volumes = null
def secretOpenTelemetry = ""
def deployVersion = "2.0.2-RC1"
def globals = null
def deployAtlasVersion = "2.0.3"

try {
  node {
    deploymentEnvironment = params.ENVIRONMENT
    stage('Preparation') {
      utils.setDeltaInit()
      cleanWs()
      checkout scm
      config_vars = readYaml file: "${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      log_monitoring_otel_filebeat = config_vars."log_monitoring_otel_filebeat"
      project   = config_vars."project"
      recipients= config_vars."recipients"
      hosted    = config_vars."hosted"
      namespace = config_vars."namespace"
      subscription = config_vars."subscription"
      containerRegistry = config_vars."containerRegistry"
      transformer_url  = config_vars."transformer_url"
      utils.notifyByMail('START', recipients)

      if (config_vars."image_filebeat" != '') {
        filebeat = config_vars."image_filebeat"
      }
      println "filebeat: ${filebeat}"
      if (hosted == 'aks') {
        aksRG = config_vars."aksRG"
        aksCluster = config_vars."aksCluster"
      }

      kafkaConnectName = config_vars."kafkaConnectName"
      connectGroupId = config_vars."connectGroupId"
      connectConfigStorageTopic = config_vars."connectConfigStorageTopic"
      connectOffsetStorageTopic = config_vars."connectOffsetStorageTopic"
      connectStatusStorageTopic = config_vars."connectStatusStorageTopic"
      secretOpenTelemetry = config_vars."secretOpenTelemetry"   
      bootstrapServer = config_vars."bootstrapServer"
      schemaRegistry = config_vars."schemaRegistry"
      imageName = config_vars."imageName"
      ms_type = config_vars."ms_type"
    
      print " kafkaConnectName -> " + kafkaConnectName
      sh "sed -i 's/\${kafkaConnectName}/${kafkaConnectName}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"      
      sh "sed -i 's/\${connectGroupId}/${connectGroupId}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's/\${connectConfigStorageTopic}/${connectConfigStorageTopic}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's/\${connectOffsetStorageTopic}/${connectOffsetStorageTopic}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's/\${connectStatusStorageTopic}/${connectStatusStorageTopic}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's/\${bootstrapServer}/${bootstrapServer}/g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's|\${schemaRegistry}|${schemaRegistry}|g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's|\${imageName}|${imageName}|g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's|\${ms_type}|${ms_type}|g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      sh "sed -i 's|\${project}|${project}|g' ${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"

      config_vars = readYaml file: "${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml"
      print "config_vars -> " + config_vars

      env.project = "${project}"
      utils.getDelta("preparation")
      utils.setHashicorpVaultEnabled(true)
      utils.setHashicorpVaultEnvironment("${deploymentEnvironment}")
      if ("${deploymentEnvironment}" == "dev" || "${deploymentEnvironment}" == "cert" ) {
        utils.setHashicorpVaultInstance(true)
        if ("${deploymentEnvironment}" == "dev") {
          utils.setHashicorpVaultNamespace("${project}".toLowerCase())
        }
      }
    }

    println "Descargando del repo base"
    descargarScriptsPEVE(utils, deploymentEnvironment, deployVersion)
    println "Termino descarga repo peve utils"

    sh "sed -i 's/\${kafkaConnectName}/${kafkaConnectName}/g' ${WORKSPACE}/devops/deploy/volumes-${hosted}.yaml"
    sh "sed -i 's/\${secretOpenTelemetry}/${secretOpenTelemetry}/g' ${WORKSPACE}/devops/deploy/volumes-${hosted}.yaml"
    sh "sed -i 's/\${env}/${deploymentEnvironment}/g' ${WORKSPACE}/devops/deploy/volumes-${hosted}.yaml"

    volumes = readYaml file: "${WORKSPACE}/devops/deploy/volumes-${hosted}.yaml"

    sh "sed -i 's/\${deploymentEnvironment}/${deploymentEnvironment}/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    sh "sed -i 's/\${project}/" + "${project}".toLowerCase() + "/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    sh "sed -i 's/\${namespace}/${namespace}/g' ${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"
    def hosted_on_environment = readYaml file: "${WORKSPACE}/devops/deploy/credentials-hv-map.yaml"

    stage('Rollback connector to ' + deploymentEnvironment) {
      utils.setDeltaInit()

      sh "ls -la devops"
      sh "mkdir -p ${WORKSPACE}/devops/docker"

      def CREDENTIAL_ID    = "${kafkaConnectName}"
      def kafkaconnectVersion = config_vars."kafkaconnectVersion"
      def kafkaConnectImageTag = config_vars."imageTag"
      def kafkaConnectDeploymentName = kafkaConnectName + "-" + kafkaconnectVersion.replace(".", "-")
      globals = readYaml file: "${WORKSPACE}/devops/deploy/global-vars.yaml"
      def logstashUrl = globals[hosted]."clusterdata"."${deploymentEnvironment}"."logstashUrl"
      def logstashPort = globals[hosted]."clusterdata"."${deploymentEnvironment}"."logstashPort"

      // Docker values
      def DOCKER_IP = sh(script: "grep \$(hostname) /etc/hosts | awk '{print \$1}'", returnStdout: true).trim()
      def DOCKER_SUPPORT_REGISTRY = "${containerRegistry}"
      def DOCKER_SUPPORT_REGISTRY_URL = "https://${DOCKER_SUPPORT_REGISTRY}"
      def DOCKER_SUPPORT_REGISTRY_CREDENTIAL = "acr-devops-${deploymentEnvironment}"
      def DOCKER_SUPPORT_IMAGE = "${DOCKER_SUPPORT_REGISTRY}/atla/atlas-docker-image-deployment-tools:${deployAtlasVersion}"
      def DOCKER_SERVER = "tcp://${DOCKER_IP}:2376"

      def ansible_cmd_common = [
        workspace                 : "${WORKSPACE}",
        hosted_on                 : hosted,
        deployment_environment    : deploymentEnvironment,
        client_k8s                : hosted_on_environment."${hosted}"."client",
        namespace                 : namespace,
        subscription              : subscription,
        project                   : "${project}".toLowerCase(),
        credentialId              : CREDENTIAL_ID,
        kafkaConnectName          : "${kafkaConnectName}",
        kafkaConnectImageTag      : "${kafkaConnectImageTag}",
        kafkaConnectDeploymentName: "${kafkaConnectDeploymentName}",
        logstash_url              : "${logstashUrl}", 
        logstash_port             : "${logstashPort}", 
        loglevel                  : "INFO",
        filebeat                  : filebeat,
        log_monitoring_otel_filebeat: log_monitoring_otel_filebeat
      ]

      def ansible_cmd = "ansible-playbook ${WORKSPACE}/devops/ansible/site_rollback.yaml -v -i ${WORKSPACE}/devops/ansible/hosts.yml " +
                        "-e @${WORKSPACE}/devops/deploy/${deploymentEnvironment}-vars.yaml " +
                        "-e @${WORKSPACE}/devops/deploy/volumes-${hosted}.yaml " +
                        "-e @${WORKSPACE}/devops/ansible/roles/vars/${deploymentEnvironment}'-vars.yaml' "
      for (item in ansible_cmd_common) {
        ansible_cmd += "-e ${item.key}=${item.value} "
      }

      utils.withHashicorpVaultCredentialAtla(hosted_on_environment[hosted].credentials, deploymentEnvironment) {
        utils.dockerWithRegistryHashicorpVaultAtla("${DOCKER_SUPPORT_REGISTRY_CREDENTIAL}", "${DOCKER_SUPPORT_REGISTRY_URL}") {
          def docker_cmd = "docker run --rm -v ${WORKSPACE}:${WORKSPACE}:rw -u 1002:1014 --network host -e DOCKER_HOST=${DOCKER_SERVER} " +
                           "-e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_CONFIG=${WORKSPACE}/devops/ansible/ansible.cfg"
          def docker_image = "${DOCKER_SUPPORT_IMAGE}"
          def ansible_cmd_extra = [:]

          if (hosted == 'aks') {
            sh "rm -fr ${WORKSPACE}/tmp; mkdir -p ${WORKSPACE}/tmp; cp AKS_CERTIFICATE ${WORKSPACE}/tmp/AKS_CERTIFICATE"
            ansible_cmd_extra << [
              aks_cluster          : "${aksCluster}",
              aks_rg               : "${aksRG}",
              aks_service_principal: "${AKS_SP}",
              aks_certificate      : "${WORKSPACE}/tmp/AKS_CERTIFICATE",
              az_tenant            : "${AZ_TENANT}"
            ]
          } else {
            ansible_cmd_extra << [
              aks_cluster: "''",
              aks_rg     : "''",
              az_username: "''",
              az_password: "''",
              az_tenant  : "''"
            ]
          }
          if (hosted == 'ocp') {
            ansible_cmd_extra << [
              azure_registry_username: "${AZURE_REGISTRY_USERNAME}",
              azure_registry_password: "${AZURE_REGISTRY_PASSWORD}"
            ]
          }
          ansible_cmd_extra << [
            azure_docker_registry     : "${containerRegistry}",
            external_registry_username: "${EXTERNAL_REGISTRY_USERNAME}",
            external_registry_password: "${EXTERNAL_REGISTRY_PASSWORD}"
          ]

          for (item in ansible_cmd_extra) {
            ansible_cmd += "-e ${item.key}=${item.value} "
          }

          sh "${docker_cmd} ${docker_image} ${ansible_cmd}"
        }
      }
      utils.getDelta("Kafka Rollback")
    }
      utils.prepare()

stage('Start Promote') {
      if ("${deploymentEnvironment}" == "cert")
            utils.startReleaseFreeStyleProject('./devops', 'tar')
    }

    stage('Post Execution') {
      utils.executePostExecutionTasks()
      utils.notifyByMail('SUCCESS', recipients)
      sh 'echo SUCCESS!'
    }
  }
} catch (Exception e) {
  node {
    utils.executeOnErrorExecutionTasks()
    utils.notifyByMail('FAIL', recipients)
    sh 'echo THERE WAS AN ERROR, REPORT TO PLATFORM!'
    throw e
  }
}

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
