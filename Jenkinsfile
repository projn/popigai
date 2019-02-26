!groovy
pipeline {
   agent any
   stages {
     stage('upload') {
       environment {
         def remote = [:]
         remote.name = 'master'
         remote.host = '192.168.37.134'
         remote.user = 'root'
         remote.password = '123456'
         remote.allowAnyHosts = true
       }
       steps {
         sshCommand remote: remote, command: "ls -lrt"
       }
     }
   }
 }