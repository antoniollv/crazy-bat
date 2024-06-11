pipeline {
  agent any
  stages {
    stage('Validar función getRepoName') {
      steps {
        echo "env.JOB_NAME: ${env.JOB_NAME}"
        echo "####"
        echo "Output getReponame.-"
        echo "####"
        echo getRepoName(env.JOB_NAME)
        echo "####"
      }
    }
  }
}

/**
    Función para recuperar el nombre del repositorio desde el job de Jenkins.
    Esto solo es así en el caso de repositorios cuyo nombre coincida el nombre del job de Jenkins
    incluidos mediante worspace o en carpeta, o el nombre del job con el que sha creado,
    no soporta subcarpetas

    @Param jobName  Nombre completo del Job en Jenkins
                    habitualmente  se obtine de la variable de entorno
                    definida por defecto env.JOB_NAME del Jenkins

**/

def getRepoName(String jobName) {
    // Recupera el nombre del repositorio desde el job de jenkins
    println ("Init getRepoName from " + jobName)
 
    def nameRepo = jobName.split('/');
    return nameRepo[1];
}

#!/usr/bin/env groovy
import com.ibermatica.utils.*

def getPullRequestURL(String workspace, String repository){
  return env.URL_API_BITBUCKET + workspace + '/' + repository + '/pullrequests'
}

def getFile(String workspace, String repository, String branch, String fileName){
  def url = env.URL_API_BITBUCKET + workspace + '/' + repository + '/src/' + branch.replaceAll('/', '%/')  + '/' + fileName
  return httpUtils.getRequest(url, BITBUCKET_CREDENTIALS)
}

def createPullRequest(String url, String dataRaw) {
  println("Init createPullRequest")
  String prResponse = httpUtils.postRequest(url, dataRaw, BITBUCKET_CREDENTIALS)
  println("End createPullRequest ---- ${getMessage(prResponse)}")
  return getMessage(prResponse)
}

def createMergeRequest(String httpMessage) {
  if (existContent(httpMessage)) {
    String mergeResponse = httpUtils.postRequest(httpMessage, '""', BITBUCKET_CREDENTIALS)
    println("HTTP Merge Response: ${getMessage(mergeResponse)}")
    return mergeResponse
  }
  println('HTTP Status: merging cannot be realized.')
  return false
}

def generateDataRaw(String repository, String destinationBranch, String sourceBranch) {
  return  """{
              "title": "PullRequest ${repository} ${sourceBranch} to ${destinationBranch}",
              "description": "Create PullRequest from ${sourceBranch} to ${destinationBranch} in ${repository} repository",
              "destination": {
                  "branch": {
                      "name": "${destinationBranch}"
                  }
              },
              "source": {
                  "branch": {
                      "name": "${sourceBranch}"
                  }
              }
          }"""
}

def declinePullRequest(String url){
  return httpUtils.postRequest(url, '""', BITBUCKET_CREDENTIALS)
}

def getHashBranch(String workspace, String repository, String branch){
  def url = env.URL_API_BITBUCKET + workspace + '/' + repository + '/refs/branches/' + branch
  String hBResponse = httpUtils.getRequest(url, BITBUCKET_CREDENTIALS)
  def jsonResponse = JsonUtils.stringToJson(hBResponse) 

  if (jsonResponse == null){
    return "getHashBranch - La llamada a la API de Bitbucket no ha retornado respuesta.\nContent: " + hBResponse
  } 
  
  try {
    return jsonResponse.target.hash
  } catch (Exception e ) { 
    return "getHashBranch - Error obteniendo el hash de la rama: [${jsonResponse.error.message}]"
  }
 
}

def getMessage(String httpResponse) {
  def jsonResponse = JsonUtils.stringToJson(httpResponse) 

  if (jsonResponse == null){
    return "getMessage - La llamada a la API de Bitbucket no ha retornado respuesta.\nContent: " + httpResponse
  } else if (jsonResponse.links == null ) {
    println("HTTP Message: ${jsonResponse.error.message}")
    return null
  } else {
    return jsonResponse.links
  }
  
}

def getMessageError(String httpResponse) {
  def jsonResponse = JsonUtils.stringToJson(httpResponse)
  
  if (jsonResponse == null){
      return "getMessageError - La llamada a la API de Bitbucket ha generado error pero no ha retornado respuesta.\nContent: "+ httpResponse
  }

  return jsonResponse.error.message 
}

def existContent(String message) {
  return message.contains('http') ? true : false
}

