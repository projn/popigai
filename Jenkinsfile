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
        sh '''cd ./installdocker-install;\\
              sh install.sh --install'''

      }
    }
  }
}