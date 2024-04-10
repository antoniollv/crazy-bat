pipeline {
  agent any
  stages {
    stage('Echo GitHub') {
      steps {
        getRepoName(env.JOB_NAME)
      }
    }
  }
}

def getRepoName(String jobName) {
    // Recupera el nombre del repositorio desde el job de jenkins
    println ("Init getRepoName from " + jobName)
 
    def nameRepo = jobName.split('/');
    return nameRepo[1];
}