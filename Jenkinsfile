node {
  def remote = [:]
  remote.name = 'master'
  remote.host = '192.168.37.134'
  remote.user = 'root'
  remote.password = '123456'
  remote.allowAnyHosts = true
  remote.allowAnyHosts = true
  stage('Remote SSH') {
    sshCommand remote: remote, command: "ls -lrt"
  }
}