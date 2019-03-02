pipeline {
  agent any
  environment {
    INSTALL_COCKROACHDB_FLAG='false'
    INSTALL_ELASTICSEARCH_FLAG='true'
    INSTALL_KAFKA_FLAG='true'
    INSTALL_REDIS_FLAG='true'
  }

  stages {

      parallel {

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
              environment name: 'INSTALL_KAFKA_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/zookeeper-install; \\
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
              environment name: 'INSTALL_KAFKA_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/zookeeper-install; \\
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
              environment name: 'INSTALL_ELASTICSEARCH_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/elasticsearch-install; \\
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

        stage('install cockroachdb') {
          environment {
            REMOTE_HOST_MASTER_IP='192.168.37.XXX'
            REMOTE_HOST_NODE_IP_LIST='192.168.37.134,192.168.37.135'
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
              environment name: 'INSTALL_COCKROACHDB_FLAG', value: 'false'
            }
          }

          steps {
            sh '''cd ./install/cockroachdb-install; \\
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
              sshCommand remote:host, command:"cd ~/cockroachdb-install;echo 'COCKROACHDB_HOST=${REMOTE_HOST_MASTER_IP}' >> config.properties;sh install.sh --install"
              sshCommand remote:host, command:"sh install.sh --create-root-certs"

              sshGet remote:host, from:"${SOFTWARE_INSTALL_PATH}/certs/ca.crt", into:"./install/cockroachdb-install/", override:true
              sshGet remote:host, from:"${SOFTWARE_INSTALL_PATH}/safe-dir/ca.key", into:"./install/cockroachdb-install/", override:true

              String hostListStr=env.REMOTE_HOST_NODE_IP_LIST

              String[] hostList = hostListStr.split(",")
              for(int i=0; i<hostList.length; i++) {
                String hostIp=hostList[i]

                def host = [:]
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
                sshCommand remote:host, command:"sh install.sh --create-node-certs"
              }
            }
          }
        }
      }
    }
  }
}