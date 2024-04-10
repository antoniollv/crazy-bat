pipeline {
  agent any
  stages {
    stage('Echo GitHub') {
      steps {
        echo "env.JOB_NAME: ${env.JOB_NAME}"
        echo "####"
        echo "Output getReponame.-"
        echo "####"
        getRepoName(env.JOB_NAME)
        echo "####"
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