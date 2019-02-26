pipeline {
  agent any
  stages {

    def remote = [:]
    remote.name = 'master'
    remote.host = '192.168.37.134'
    remote.user = 'root'
    remote.password = '123456'
    remote.allowAnyHosts = true

    stage('upload') {
      steps {
        sshCommand remote: remote, command: "ls -lrt"
      }
    }
  }
}