@Library('jenkins-sharedlib@master')
import sharedlib.JenkinsfileUtil
def utils = new JenkinsfileUtil(steps,this)
/* Project settings */
def project="[CODAPP]"
/* Mail configuration*/
// If recipients is null the mail is sent to the person who start the job
// The mails should be separated by commas(',')
def recipients=""
def deploymentEnviroment="cert"
try {
   node {
     stage('Preparation') {
         utils.notifyByMail('START',recipients)
         checkout scm
         utils.prepare()
         //Setup parameters
         env.project="${project}"
      }
      stage('Pre-Release') {
         utils.startReleaseMaven()
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

