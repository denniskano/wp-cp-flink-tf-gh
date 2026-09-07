@Library('jenkins-sharedlib@master')
import sharedlib.JenkinsfileUtil
def utils = new JenkinsfileUtil(steps,this)
/* Project settings */
def project="[CODAPP]"
/* Mail configuration*/
// If recipients is null the mail is sent to the person who start the job
// The mails should be separated by commas(',')
def recipients=""
def deploymentEnvironment="prod"
try {
   node {
      stage('Preparation') {
         utils.notifyByMail('START',recipients)
         checkout scm
         env.project="${project}"
         env.deploymentEnvironment = deploymentEnvironment
         utils.prepare()
      }
      stage('Release') {
            utils.promoteReleaseMaven(params.RELEASE_TAG_NAME, true)
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

