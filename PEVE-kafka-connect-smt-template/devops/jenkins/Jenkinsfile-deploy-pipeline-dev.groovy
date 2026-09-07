@Library('jenkins-sharedlib@master')
import sharedlib.JenkinsfileUtil
def utils = new JenkinsfileUtil(steps,this)
/* Project settings */
def project="[CODAPP]"
/* Mail configuration*/
// If recipients is null the mail is sent to the person who start the job
// The mails should be separated by commas(',')
def recipients=""
def deploymentEnviroment="dev"
try {
   node {
      stage('Preparation') {
         utils.notifyByMail('START',recipients)
         checkout scm
         utils.prepare()
         env.project="${project}"
      }
      stage('Build & U.Test') {
        utils.buildMaven()
      }
      stage('QA Analisys') {
        utils.executeSonar()
      }
      stage('Upload Artifact') {
         utils.deployArtifactoryMaven()
      }
      stage('Save Results') {
         utils.saveResultMaven('jar')
      }
              	  
      stage('Post Execution') {
         utils.executePostExecutionTasks()
         utils.notifyByMail('SUCCESS',recipients)
      }
   }
} catch(Exception e) {
   node{
      utils.executeOnErrorExecutionTasks()
      utils.notifyByMail('FAIL',recipients)
    throw e
   }
}
