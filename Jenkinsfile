pipeline {
  agent any
  stages {
    stage('install harbor') {
      environment {
        REMOTE_HOST_IP=
        REMOTE_HOST_USER=root
        REMOTE_HOST_PWD=

        HARBOR_HOST=192.168.37.XXX
        HARBOR_SSH_FLAG=false
      }

      when {
        not {
          environment name: 'REMOTE_HOST_IP', value: ''
        }
      }

      steps {
        sh 'cd ./install/harbor-install'
        sh 'sh install --package'
        script {
          def local = [:]
          local.name = habor
          local.host = env.REMOTE_HOST_IP
          local.user = env.REMOTE_HOST_USER
          local.password = env.REMOTE_HOST_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/harbor-install"
          sshPut remote:local, from:"./install/harbor-install", into:"."
          sshCommand remote:local, command:"cd ~/harbor-install;sh install.sh --install"
        }
      }
    }

    stage('install nexus') {
      environment {
        REMOTE_HOST_IP=
        REMOTE_HOST_USER=root
        REMOTE_HOST_PWD=

        NEXUS_BIND_IP=192.168.37.XXX
        NEXUS_PORT=8082
      }

      when {
        not {
          environment name: 'REMOTE_HOST_IP', value: ''
        }
      }
      steps {
        sh 'cd ./install/openjdk-install'
        sh 'sh install --package'

        sh 'cd ./install/maven-install'
        sh 'sh install --package'

        sh 'cd ./install/nexus-install'
        sh 'sh install --package'
        script {
          def local = [:]
          local.name = nexus
          local.host = env.REMOTE_HOST_IP
          local.user = env.REMOTE_HOST_USER
          local.password = env.REMOTE_HOST_PWD
          local.allowAnyHosts = true

          sshCommand remote:local, command:"rm -rf ~/openjdk-install"
          sshPut remote:local, from:"./install/openjdk-install", into:"."
          sshCommand remote:local, command:"cd ~/openjdk-install;sh install.sh --install"

          sshCommand remote:local, command:"rm -rf ~/maven-install"
          sshPut remote:local, from:"./install/maven-install", into:"."
          sshCommand remote:local, command:"cd ~/maven-install;sh install.sh --install"

          sshPut remote:local, from:"./install/nexus-install", into:"."
          sshCommand remote:local, command:"cd ~/nexus-install;sh install.sh --install"
        }

      }
    }
  }
}