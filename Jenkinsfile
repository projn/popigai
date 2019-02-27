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
          def local = [:]
          local.name = 'local'
          local.host = '192.168.37.133'
          local.user = 'root'
          local.password = '123456'
          local.allowAnyHosts = true

          sshPut remote:local,from:"./install/docker-install",into:"~/"
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }
      }
    }
  }
}