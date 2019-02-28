pipeline {
  agent any
  stages {
    stage('install jdk') {
      steps {
        script {
          def local = [:]
          local.name = 'local'
          local.host = 'localhost'
          local.user = 'root'
          local.password = env.LOCAL_HOST_ROOT_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/maven-install"
          sshPut remote:local, from:"./install/maven-install", into:"."
          sshCommand remote:local, command:"cd ~/maven-install;sh install.sh --package;sh install.sh --install"
          sshPut remote:local, from:"./install/docker-install", into:"."
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }

      }
    }

    stage('install maven') {
      steps {
        script {
          def local = [:]
          local.name = 'local'
          local.host = 'localhost'
          local.user = 'root'
          local.password = env.LOCAL_HOST_ROOT_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/maven-install"
          sshPut remote:local, from:"./install/maven-install", into:"."
          sshCommand remote:local, command:"cd ~/maven-install;sh install.sh --package;sh install.sh --install"
          sshPut remote:local, from:"./install/docker-install", into:"."
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }

      }
    }

    stage('install harbor') {
      steps {
        environment {
          LOCAL_HOST_ROOT_PWD = '123456'
        }
        script {
          def local = [:]
          local.name = 'local'
          local.host = 'localhost'
          local.user = 'root'
          local.password = env.LOCAL_HOST_ROOT_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/maven-install"
          sshPut remote:local, from:"./install/maven-install", into:"."
          sshCommand remote:local, command:"cd ~/maven-install;sh install.sh --package;sh install.sh --install"
          sshPut remote:local, from:"./install/docker-install", into:"."
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }

      }
    }
    stage('install nexus') {
      steps {
        script {
          def local = [:]
          local.name = 'local'
          local.host = 'localhost'
          local.user = 'root'
          local.password = env.LOCAL_HOST_ROOT_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/maven-install"
          sshPut remote:local, from:"./install/maven-install", into:"."
          sshCommand remote:local, command:"cd ~/maven-install;sh install.sh --package;sh install.sh --install"
          sshPut remote:local, from:"./install/docker-install", into:"."
          sshCommand remote:local, command:"cd ~/docker-install;sh install.sh --install"
        }

      }
    }
  }
}