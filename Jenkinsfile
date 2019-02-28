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
                  echo "HARBOR_HOST=${HARBOR_HOST}" >> config.properties; \\
                  echo "HARBOR_SSH_FLAG=${HARBOR_SSH_FLAG}" >> config.properties'''

            script {
              def host = [:]
              host.name = 'habor'
              host.host = env.REMOTE_HOST_IP
              host.user = env.REMOTE_HOST_USER
              host.password = env.REMOTE_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/harbor-install"
              sshPut remote:host, from:"./install/harbor-install", into:"."
              sshCommand remote:host, command:"cd ~/harbor-install;sh install.sh --install"
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
            sh '''cd ./install/maven-install; \\'''
            sh '''cd ./install/nexus-install; \\
                  echo "NEXUS_BIND_IP=${NEXUS_BIND_IP}" >> config.properties; \\
                  echo "NEXUS_PORT=${NEXUS_PORT}" >> config.properties'''

            script {
              def host = [:]
              host.name = 'nexus'
              host.host = env.REMOTE_HOST_IP
              host.user = env.REMOTE_HOST_USER
              host.password = env.REMOTE_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/openjdk-install"
              sshPut remote:host, from:"./install/openjdk-install", into:"."
              sshCommand remote:host, command:"cd ~/openjdk-install;sh install.sh --install"

              sshCommand remote:host, command:"rm -rf ~/maven-install"
              sshPut remote:host, from:"./install/maven-install", into:"."
              sshCommand remote:host, command:"cd ~/maven-install;sh install.sh --install"

              sshCommand remote:host, command:"source /etc/profile"

              sshPut remote:host, from:"./install/nexus-install", into:"."
              sshCommand remote:host, command:"cd ~/nexus-install;sh install.sh --install"
            }
          }
        }
      }
    }
  }
}