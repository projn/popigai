pipeline {
  agent any
  environment {
    PACKAGE_REPO_DIR=''
    INSTALL_HARBOR_FLAG='true'
    INSTALL_NEXUS_FLAG='true'

  }

  stages {
    stage('repo') {
      parallel {
        stage('install harbor') {
          environment {
            REMOTE_HOST_IP='192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            HARBOR_HOST='192.168.37.XXX'
            HARBOR_SSH_FLAG='false'
          }

          when {
            not {
              environment name: 'INSTALL_HARBOR_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/harbor-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
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
            REMOTE_HOST_IP='192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            NEXUS_BIND_IP='192.168.37.XXX'
            NEXUS_PORT='8082'
            MAVEN_INSTALL_NEXUS_SETTING='false'
          }

          when {
            not {
              environment name: 'INSTALL_NEXUS_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/maven-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  echo "MAVEN_INSTALL_NEXUS_SETTING=${MAVEN_INSTALL_NEXUS_SETTING}" >> config.properties; \\
                  sh install.sh --package'''
            sh '''cd ./install/nexus-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
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