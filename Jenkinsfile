pipeline {
   agent any
   environment {
     def remote = ''
   }
   stages {
     stage('upload') {
       steps {
         remote = [:]
         remote.name = 'master'
         remote.host = '192.168.37.134'
         remote.user = 'root'
         remote.password = '123456'
         remote.allowAnyHosts = true
         sshCommand remote: remote, command: "ls -lrt"
       }
     }
   }
 }