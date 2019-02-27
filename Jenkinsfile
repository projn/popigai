pipeline {
  agent any
  stages {
    stage('prepare jenkins') {
      agent {
        node {
          label 'dev'
        }
      }
      steps {
        sh '''cd ./install/docker-install;\\
              sh install.sh --install'''

      }
    }
  }
}