pipeline {
  agent any
  stages {
    stage('upload') {
      environment {
        remote = '[:]'
      }
      steps {
        sshCommand(remote: remote, command: 'ls -lrt', sudo: true)
      }
    }
  }
  environment {
    server = ''
  }
}