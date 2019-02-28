pipeline {
  agent any
  environment {
    INSTALL_HARBOR_FLAG='false'
    INSTALL_NEXUS_FLAG='true'
  }

  stages {
    stage('repo') {
      parallel {
        stage('install harbor') {
          environment {
            REMOTE_HOST_IP='192.168.37.134'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            HARBOR_HOST='192.168.37.134'
            HARBOR_SSH_FLAG='false'
          }

          when {
            not {
              environment name: 'INSTALL_HARBOR_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/harbor-install; \\
                  sh install.sh --package; \\
                  echo "HARBOR_HOST=${HARBOR_HOST}" >> config.properties; \\
                  echo "HARBOR_SSH_FLAG=${HARBOR_SSH_FLAG}" >> config.properties'''

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
            REMOTE_HOST_IP='192.168.37.134'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            NEXUS_BIND_IP='192.168.37.134'
            NEXUS_PORT='8082'
          }

          when {
            not {
              environment name: 'INSTALL_NEXUS_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/openjdk-install; \\
                  sh install.sh --package; \\
                  cd ./install/maven-install; \\
                  sh install.sh --package; \\
                  cd ./install/nexus-install; \\
                  sh install.sh --package; \\
                  echo "NEXUS_BIND_IP=${NEXUS_BIND_IP}" >> config.properties; \\
                  echo "NEXUS_PORT=${NEXUS_PORT}" >> config.properties'''

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

              sshCommand remote:local, command:"source /etc/profile"

              sshPut remote:local, from:"./install/nexus-install", into:"."
              sshCommand remote:local, command:"cd ~/nexus-install;sh install.sh --install"
            }
          }
        }
      }
    }
  }
}