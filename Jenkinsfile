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
        script {
          cd docker-install
          sh install.sh --install
        }

      }
    }
  }
}