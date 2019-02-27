pipeline {
  agent {
    node {
      label 'dev'
    }

  }
  stages {
    stage('prepare jenkins') {
      steps {
        script {
          def local = [:]
          local.name = 'local'
          local.host = 'localhost'
          local.user = 'root'
          local.password = ${LOCAL_HOST_ROOT_PWD}
          local.allowAnyHosts = true

          sshPut remote:local,from:"./install/docker-install",into:"."
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }

      }
    }
  }
  environment {
    LOCAL_HOST_ROOT_PWD = '123456'
  }
}