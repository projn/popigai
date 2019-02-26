pipeline {
   agent any
   environment {
     def server = ''
   }
   stages {
     stage('upload') {
       steps {
         sshCommand remote: remote, command: "ls -lrt"
       }
     }
   }
 }