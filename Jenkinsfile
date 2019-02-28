pipeline {
  agent any
  environment {
    INSTALL_CONIFIG_SERVER_FLAG='true'
    INSTALL_CONSUL_FLAG='true'
    INSTALL_ZIPKIN_FLAG='true'
    INSTALL_KONG_FLAG='false'




  }

  stages {
    stage('repo') {
      parallel {
        stage('install config server') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.133,192.168.37.134,192.168.37.135'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            SOFTWARE_SERVER_IP=192.168.37.XXX
            SOFTWARE_SERVER_PORT=10443
            SOFTWARE_GIT_REMOTE_REPO_URL=https://github.com/XXX.git
            SOFTWARE_GIT_REMOTE_REPO_USERNAME=XXX
            SOFTWARE_GIT_REMOTE_REPO_PASSWORD=XXX
            SOFTWARE_GIT_LOCAL_REPO_LABEL=master
            SOFTWARE_GIT_LOCAL_REPO_DIR=/opt/datastore/alpsconfigserver/config
            SOFTWARE_ACL_KEY_PATH=/opt/software/alpsconfigserver/context/server.jks
            SOFTWARE_ACL_KEY_PASSWORD=XXX
            SOFTWARE_ACL_KEY_ALIAS=XXX
            SOFTWARE_ACL_KEY_SECRET=XXX
            SOFTWARE_CONSUL_SERVER_ADDRESS=192.168.37.XXX
            SOFTWARE_CONSUL_PORT=8500
          }

          when {
            not {
              environment name: 'INSTALL_CONIFIG_SERVER_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/alpsconfigserver-install; \\
                  echo "SOFTWARE_SERVER_IP=${SOFTWARE_SERVER_IP}" >> config.properties; \\
                  echo "SOFTWARE_SERVER_PORT=${SOFTWARE_SERVER_PORT}" >> config.properties; \\
                  echo "SOFTWARE_GIT_REMOTE_REPO_URL=${SOFTWARE_GIT_REMOTE_REPO_URL}" >> config.properties; \\
                  echo "SOFTWARE_GIT_REMOTE_REPO_USERNAME=${SOFTWARE_GIT_REMOTE_REPO_USERNAME}" >> config.properties; \\
                  echo "SOFTWARE_GIT_LOCAL_REPO_LABEL=${SOFTWARE_GIT_LOCAL_REPO_LABEL}" >> config.properties; \\
                  echo "SOFTWARE_GIT_LOCAL_REPO_DIR=${SOFTWARE_GIT_LOCAL_REPO_DIR}" >> config.properties; \\
                  echo "SOFTWARE_ACL_KEY_PATH=${SOFTWARE_ACL_KEY_PATH}" >> config.properties; \\
                  echo "SOFTWARE_ACL_KEY_PASSWORD=${SOFTWARE_ACL_KEY_PASSWORD}" >> config.properties; \\
                  echo "SOFTWARE_ACL_KEY_ALIAS=${SOFTWARE_ACL_KEY_ALIAS}" >> config.properties; \\
                  echo "SOFTWARE_ACL_KEY_SECRET=${SOFTWARE_ACL_KEY_SECRET}" >> config.properties; \\
                  echo "SOFTWARE_CONSUL_SERVER_ADDRESS=${SOFTWARE_CONSUL_SERVER_ADDRESS}" >> config.properties; \\
                  echo "SOFTWARE_CONSUL_PORT=${SOFTWARE_CONSUL_PORT}" >> config.properties'''

            script {
              def host = [:]
              host.name = 'config'
              host.host = env.REMOTE_HOST_IP
              host.user = env.REMOTE_HOST_USER
              host.password = env.REMOTE_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/alpsconfigserver-install"
              sshPut remote:host, from:"./install/alpsconfigserver-install", into:"."
              sshCommand remote:host, command:"cd ~/alpsconfigserver-install;sh install.sh --install"
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