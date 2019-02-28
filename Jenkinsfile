pipeline {
  agent any
  environment {
    INSTALL_CONIFIG_SERVER_FLAG='true'
    INSTALL_CONSUL_FLAG='true'
    INSTALL_ZIPKIN_FLAG='true'
    INSTALL_KONG_FLAG='false'
  }

  stages {
    stage('cloud') {
      parallel {
        stage('install config server') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.134,192.168.37.135'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            SOFTWARE_SERVER_PORT='10443'
            SOFTWARE_GIT_REMOTE_REPO_URL='https://github.com/XXX.git'
            SOFTWARE_GIT_REMOTE_REPO_USERNAME='XXX'
            SOFTWARE_GIT_REMOTE_REPO_PASSWORD='XXX'
            SOFTWARE_GIT_LOCAL_REPO_LABEL='master'
            SOFTWARE_GIT_LOCAL_REPO_DIR='/opt/datastore/alpsconfigserver/config'
            SOFTWARE_ACL_KEY_PATH='/opt/software/alpsconfigserver/context/server.jks'
            SOFTWARE_ACL_KEY_PASSWORD='XXX'
            SOFTWARE_ACL_KEY_ALIAS='XXX'
            SOFTWARE_ACL_KEY_SECRET='XXX'
            SOFTWARE_CONSUL_SERVER_ADDRESS='192.168.37.XXX'
            SOFTWARE_CONSUL_PORT='8500'
          }

          when {
            not {
              environment name: 'INSTALL_CONIFIG_SERVER_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/alpsconfigserver-install; \\
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
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'config'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/alpsconfigserver-install"
                sshPut remote:host, from:"./install/alpsconfigserver-install", into:"."
                sshCommand remote:host, command:"cd ~/alpsconfigserver-install;echo 'SOFTWARE_SERVER_IP=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }

        stage('install consul') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.134,192.168.37.135'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            CONSUL_HTTP_PORT='8080'
            CONSUL_CLUSTER_CONFIG='"192.168.37.XXX","192.168.37.XXX","192.168.37.XXX"'
          }

          when {
            not {
              environment name: 'INSTALL_CONIFIG_SERVER_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/consul-install; \\
                  echo "CONSUL_HTTP_PORT=${CONSUL_HTTP_PORT}" >> config.properties; \\
                  echo "CONSUL_CLUSTER_CONFIG=${CONSUL_CLUSTER_CONFIG}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'config'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/consul-install"
                sshPut remote:host, from:"./install/consul-install", into:"."
                sshCommand remote:host, command:"cd ~/consul-install;echo 'CONSUL_NODE_NAME=node${i}' >> config.properties;echo 'CONSUL_BIND_IP=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }
      }
    }
  }
}