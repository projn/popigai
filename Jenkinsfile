def getHost() {
  def remote = [:]
   remote.name = 'master'
   remote.host = '192.168.37.134'
   remote.user = 'root'
   remote.password = '123456'
   remote.allowAnyHosts = true
   return remote
}

pipeline {
   agent any
       environment {
         def remote = ''
       }
   stages {
        stage('init') {
          steps {
            script {
              remote=getHost()
            }
          }
        }
     stage('upload') {
       steps {
         sshCommand remote: remote, command: "ls -lrt"
       }
     }
   }
 }