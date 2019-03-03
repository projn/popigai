pipeline {
  agent any
  environment {
    PACKAGE_REPO_DIR=''
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
            REMOTE_HOST_IP_LIST='192.168.37.XXX,192.168.37.XXX,192.168.37.XXX'
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

                sshCommand remote:host, command:"rm -rf ~/openjdk-install"
                sshPut remote:host, from:"./install/openjdk-install", into:"."
                sshCommand remote:host, command:"cd ~/openjdk-install;sh install.sh --install"

                sshCommand remote:host, command:"source /etc/profile"

                sshCommand remote:host, command:"rm -rf ~/alpsconfigserver-install"
                sshPut remote:host, from:"./install/alpsconfigserver-install", into:"."
                sshCommand remote:host, command:"cd ~/alpsconfigserver-install;echo 'SOFTWARE_SERVER_IP=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }

        stage('install consul') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.XXX,192.168.37.XXX,192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            CONSUL_HTTP_PORT='8080'
            CONSUL_CLUSTER_CONFIG='"192.168.37.XXX","192.168.37.XXX","192.168.37.XXX"'
          }

          when {
            not {
              environment name: 'INSTALL_CONSUL_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/consul-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "CONSUL_HTTP_PORT=${CONSUL_HTTP_PORT}" >> config.properties; \\
                  echo "CONSUL_CLUSTER_CONFIG=${CONSUL_CLUSTER_CONFIG}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'consul'
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

        stage('install zookeeper') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.XXX,192.168.37.XXX,192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            ZOOKEEPER_CLUSTER_HOST_LIST='("192.168.37.XXX" "192.168.37.XXX" "192.168.37.XXX")'
            ZOOKEEPER_CLIENT_PORT='2181'
          }

          when {
            not {
              environment name: 'INSTALL_ZIPKIN_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/zookeeper-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "ZOOKEEPER_CLUSTER_HOST_LIST=${ZOOKEEPER_CLUSTER_HOST_LIST}" >> config.properties; \\
                  echo "ZOOKEEPER_CLIENT_PORT=${ZOOKEEPER_CLIENT_PORT}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'zookeeper'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/zookeeper-install"
                sshPut remote:host, from:"./install/zookeeper-install", into:"."
                sshCommand remote:host, command:"cd ~/zookeeper-install;sh install.sh --install"
              }
            }
          }
        }

        stage('install kafka') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.XXX,192.168.37.XXX,192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            KAFKA_LISTENER_PORT='9092'
            ZOOKEEPER_CLUSTER_INFO='"192.168.37.XXX:2181,192.168.37.XXX:2181,192.168.37.XXX:2181"'
          }

          when {
            not {
              environment name: 'INSTALL_ZIPKIN_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/zookeeper-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "KAFKA_LISTENER_PORT=${KAFKA_LISTENER_PORT}" >> config.properties; \\
                  echo "ZOOKEEPER_CLUSTER_INFO=${ZOOKEEPER_CLUSTER_INFO}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'kafka'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/zookeeper-install"
                sshPut remote:host, from:"./install/zookeeper-install", into:"."
                sshCommand remote:host, command:"cd ~/zookeeper-install;echo 'KAFKA_BROKER_ID=${i}' >> config.properties;echo 'KAFKA_LISTENER_HOST=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }

        stage('install elasticsearch') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.XXX,192.168.37.XXX,192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            ELASTICSEARCH_PORT='9200'
            ELASTICSEARCH_CLUSTER_HOST_LIST='"192.168.37.XXX","192.168.37.XXX","192.168.37.XXX"'
          }

          when {
            not {
              environment name: 'INSTALL_ZIPKIN_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/elasticsearch-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT}" >> config.properties; \\
                  echo "ELASTICSEARCH_CLUSTER_HOST_LIST=${ELASTICSEARCH_CLUSTER_HOST_LIST}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'elasticsearch'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/elasticsearch-install"
                sshPut remote:host, from:"./install/elasticsearch-install", into:"."
                sshCommand remote:host, command:"cd ~/elasticsearch-install;echo 'ELASTICSEARCH_NODE_NAME=node${i}' >> config.properties;echo 'ELASTICSEARCH_HOST=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }

        stage('install zipkin') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.134,192.168.37.135'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            ZIPKIN_KAFKA_BOOTSTRAP_SERVERS='192.168.37.XXX:9092,192.168.37.XXX:9092,192.168.37.XXX:9092'
            ZIPKIN_ES_HOSTS='192.168.37.XXX:9200,192.168.37.XXX:9200,192.168.37.XXX:9200'
            ZIPKIN_QUERY_PORT='9411'
          }

          when {
            not {
              environment name: 'INSTALL_ZIPKIN_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/zipkin-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "ZIPKIN_KAFKA_BOOTSTRAP_SERVERS=${ZIPKIN_KAFKA_BOOTSTRAP_SERVERS}" >> config.properties; \\
                  echo "ZIPKIN_QUERY_PORT=${ZIPKIN_QUERY_PORT}" >> config.properties; \\
                  echo "ZIPKIN_ES_HOSTS=${ZIPKIN_ES_HOSTS}" >> config.properties'''

            script {
              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
                host.name = 'zipkin'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/zipkin-install"
                sshPut remote:host, from:"./install/zipkin-install", into:"."
                sshCommand remote:host, command:"cd ~/zipkin-install;echo 'ZIPKIN_HOST=${hostIp}' >> config.properties;sh install.sh --install"
              }
            }
          }
        }

        stage('install cockroachdb') {
          environment {
            REMOTE_HOST_MASTER_IP='192.168.37.XXX'
            REMOTE_HOST_NODE_IP_LIST='192.168.37.XXX,192.168.37.XXX'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            SOFTWARE_INSTALL_PATH='/opt/software/cockroachdb'
            SOFTWARE_USER_GROUP='cloudgrp'
            SOFTWARE_USER_NAME='cloud'
            COCKROACHDB_MASTER_HOSTS='192.168.37.XXX:26257'
            COCKROACHDB_NODE_HOST_LIST='("192.168.37.XXX" "192.168.37.XXX")'
            COCKROACHDB_PORT='26257'
            COCKROACHDB_UI_PORT='8080'
          }

          when {
            not {
              environment name: 'INSTALL_KONG_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/cockroachdb-install; \\
                  echo "PACKAGE_REPO_DIR=${PACKAGE_REPO_DIR}" >> config.properties; \\
                  sh install.sh --package; \\
                  echo "SOFTWARE_INSTALL_PATH=${SOFTWARE_INSTALL_PATH}" >> config.properties; \\
                  echo "SOFTWARE_USER_GROUP=${SOFTWARE_USER_GROUP}" >> config.properties; \\
                  echo "SOFTWARE_USER_NAME=${SOFTWARE_USER_NAME}" >> config.properties; \\
                  echo "COCKROACHDB_MASTER_HOSTS=${COCKROACHDB_MASTER_HOSTS}" >> config.properties; \\
                  echo "COCKROACHDB_NODE_HOST_LIST=${COCKROACHDB_NODE_HOST_LIST}" >> config.properties; \\
                  echo "COCKROACHDB_UI_PORT=${COCKROACHDB_UI_PORT}" >> config.properties; \\
                  echo "COCKROACHDB_PORT=${COCKROACHDB_PORT}" >> config.properties'''

            script {

              def host = [:]
              host.name = 'config'
              host.host = env.REMOTE_HOST_MASTER_IP
              host.user = env.REMOTE_HOST_USER
              host.password = env.REMOTE_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/cockroachdb-install"
              sshPut remote:host, from:"./install/cockroachdb-install", into:"."
              sshCommand remote:host, command:"cd ~/cockroachdb-install;echo 'COCKROACHDB_HOST=${REMOTE_HOST_MASTER_IP}' >> config.properties;sh install.sh --install;sh install.sh --create-root-certs"

              sshGet remote:host, from:"${SOFTWARE_INSTALL_PATH}/certs/ca.crt", into:"./install/cockroachdb-install/", override:true
              sshGet remote:host, from:"${SOFTWARE_INSTALL_PATH}/safe-dir/ca.key", into:"./install/cockroachdb-install/", override:true

              String hostListStr=env.REMOTE_HOST_NODE_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                host = [:]
                host.name = 'config'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/cockroachdb-install"
                sshCommand remote:host, command:"cd ~/cockroachdb-install;echo 'COCKROACHDB_HOST=${hostIp}' >> config.properties;sh install.sh --install"
                sshCommand remote:host, command:"mkdir -p ${SOFTWARE_INSTALL_PATH}/certs"
                sshCommand remote:host, command:"mkdir -p ${SOFTWARE_INSTALL_PATH}/safe-dir"
                sshPut remote:host, from:"./install/cockroachdb-install", into:"${SOFTWARE_INSTALL_PATH}/certs/ca.crt"
                sshPut remote:host, from:"./install/cockroachdb-install", into:"${SOFTWARE_INSTALL_PATH}/safe-dir/ca.key"
                sshCommand remote:host, command:"chown -R ${SOFTWARE_USER_NAME}:${SOFTWARE_USER_GROUP} ${SOFTWARE_INSTALL_PATH}"
                sshCommand remote:host, command:"cd ~/cockroachdb-install;sh install.sh --create-node-certs"
              }
            }
          }
        }

        stage('install kong') {
          environment {
            REMOTE_HOST_IP_LIST='192.168.37.134,192.168.37.135'
            REMOTE_HOST_USER='root'
            REMOTE_HOST_PWD='123456'
            KONG_POSTGRES_IP='192.168.34.XXX'
            KONG_POSTGRES_HOST_IP='192.168.34.XXX'
            KONG_POSTGRES_HOST_USER='root'
            KONG_POSTGRES_HOST_PWD='123456'
            KONG_POSTGRES_PORT='5432'
            KONG_POSTGRES_DATABASE_NAME='kong'
            KONG_POSTGRES_USER='kong'
            KONG_POSTGRES_PASSWORD='kong'
            KONG_ADMIN_LISTEN_IP='0.0.0.0'
            KONG_DB_UPDATE_FREQUENCY_SECOND='5'
          }

          when {
            not {
              environment name: 'INSTALL_KONG_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/kong-install; \\
                  echo "KONG_POSTGRES_IP=${KONG_POSTGRES_IP}" >> config.properties; \\
                  echo "KONG_POSTGRES_PORT=${KONG_POSTGRES_PORT}" >> config.properties; \\
                  echo "KONG_POSTGRES_DATABASE_NAME=${KONG_POSTGRES_DATABASE_NAME}" >> config.properties; \\
                  echo "KONG_POSTGRES_USER=${KONG_POSTGRES_USER}" >> config.properties; \\
                  echo "KONG_ADMIN_LISTEN_IP=${KONG_ADMIN_LISTEN_IP}" >> config.properties; \\
                  echo "KONG_DB_UPDATE_FREQUENCY_SECOND=${KONG_DB_UPDATE_FREQUENCY_SECOND}" >> config.properties; \\
                  echo "KONG_POSTGRES_PASSWORD=${KONG_POSTGRES_PASSWORD}" >> config.properties'''

            script {
              def host = [:]
              host.name = 'postgres'
              host.host = env.KONG_POSTGRES_HOST_IP
              host.user = env.KONG_POSTGRES_HOST_USER
              host.password = env.KONG_POSTGRES_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/kong-install"
              sshPut remote:host, from:"./install/kong-install", into:"."
              sshCommand remote:host, command:"cd ~/kong-install;sh install.sh --install-db"

              String hostListStr=env.REMOTE_HOST_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                host = [:]
                host.name = 'kong'
                host.host = "${hostIp}"
                host.user = env.REMOTE_HOST_USER
                host.password = env.REMOTE_HOST_PWD
                host.allowAnyHosts = 'true'

                sshCommand remote:host, command:"rm -rf ~/kong-install"
                sshPut remote:host, from:"./install/kong-install", into:"."
                sshCommand remote:host, command:"cd ~/kong-install;sh install.sh --install"
              }
            }
          }
        }
      }
    }
  }
}