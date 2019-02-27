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
        sh '''cd docker-install;\\
              sh install.sh --install'''

      }
    }
  }
}