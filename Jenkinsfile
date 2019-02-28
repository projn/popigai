pipeline {
  agent any
  environment {
    REMOTE_HOST_IP='192.168.37.134'
    REMOTE_HOST_USER='root'
    REMOTE_HOST_PWD='123456'
    JENKINS_BIND_IP='192.168.37.134'
    JENKINS_PORT='8081'
  }

  stages {
    stage('build') {
      parallel {
        stage('install docker') {
          steps {
            script {
              def host = [:]
              host.name = 'docker'
              host.host = env.REMOTE_HOST_IP
              host.user = env.REMOTE_HOST_USER
              host.password = env.REMOTE_HOST_PWD
              host.allowAnyHosts = 'true'

              sshCommand remote:host, command:"rm -rf ~/docker-install"
              sshPut remote:host, from:"./install/docker-install", into:"."
              sshCommand remote:host, command:"cd ~/docker-install;sh install.sh --install"
            }
          }
        }

        stage('install jenkins') {
          steps {
            if[ -f "./install/maven-install/apache-maven-3.6.0-bin.tar.gz"]; then
              sh '''echo "hello"'''
            fi
            script {
              def host = [:]
              host.name = 'jenkins'
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

              sshPut remote:host, from:"./install/jenkins-install", into:"."
              sshCommand remote:host, command:"cd ~/jenkins-install;sh install.sh --install"
            }
          }
        }
      }
    }
  }
}