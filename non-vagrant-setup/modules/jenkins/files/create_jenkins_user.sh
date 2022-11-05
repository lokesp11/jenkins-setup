#!/bin/sh

if [ -s "/var/lib/jenkins/secrets/initialAdminPassword" ]; then
  echo "using initial admin password"
  initPass=`cat /var/lib/jenkins/secrets/initialAdminPassword`
  if [ -f "/tmp/jenkins-cli.jar" ]; then
    echo "deleting old jenkins jar file"
    sudo rm -f /tmp/jenkins-cli.jar
  fi
  echo "downloading jenkins jar file"
  wget http://127.0.0.1:8000/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
  echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("admin1", "pass123")' | java -jar /tmp/jenkins-cli.jar -s http://localhost:8000/ -auth admin:"$initPass" groovy =
  if grep -q admin1 /var/lib/jenkins/users/users.xml ; then
    echo "Added new user: admin1 with password: pass123"
  else
    echo "Failed creating admin user"
  fi
else
  echo "initial admin password file not found or is empty. Please troubleshoot"
fi
