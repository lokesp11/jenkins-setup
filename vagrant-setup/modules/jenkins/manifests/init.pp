class jenkins {

# To install jre
package { 'openjdk-11-jre':
  ensure => installed,
}

#Installing jenkins keys
exec { 'install-jenkins-keys':
  command => "sudo wget --dns-timeout=10 --connect-timeout=10 --inet4-only https://pkg.jenkins.io/debian/jenkins.io.key -O /usr/share/keyrings/jenkins-keyring.asc",
  creates => "/usr/share/keyrings/jenkins-keyring.asc",
  onlyif => "test ! -f /usr/share/keyrings/jenkins-keyring.asc",
  path => ['/usr/bin', '/usr/sbin'],
}

#Adding jenkins repo
exec { 'add-jenkins-repo':
  command => "echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
  creates => "/etc/apt/sources.list.d/jenkins.list",
  onlyif => "test ! -f /etc/apt/sources.list.d/jenkins.list",
  path => ['/usr/bin', '/usr/sbin'],
}

#Updating the repo cache as we are looking for latest jenkins package
exec { 'apt-update':
    command => "apt-get update",
    path => ['/usr/bin', '/usr/sbin'],
    require => Exec['install-jenkins-keys','add-jenkins-repo']
}

#Adding sleep as even after require relationship in jenkins package sometimes deployment compaints for package not found.
exec { 'sleep':
    command => "sleep 5",
    path => ['/usr/bin', '/usr/sbin'],
    require => Exec['apt-update']
}

#Installing jenkins latest package
package { 'jenkins':
    ensure => latest,
    require  => [ Exec['apt-update'], Package['openjdk-11-jre']],
  }

#Registering systemd service
service { 'jenkins':
   ensure  => running,
   require => Package['jenkins'],
}

#Perform daemon reload
exec { 'systemd-reload':
  command     => 'sudo systemctl daemon-reload',
  path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
  refreshonly => true,
}

#Updating jenkins port to 8000
exec { 'change_jenkins_port':
  command => "sed -i 's/.*JENKINS_PORT.*/Environment=\"JENKINS_PORT=8000\"/' /lib/systemd/system/jenkins.service",
  require => Package['jenkins'],
  notify => [Exec['systemd-reload'],Service['jenkins']],
  path => ['/usr/bin', '/usr/sbin'],
  unless => "grep JENKINS_PORT=8000 /lib/systemd/system/jenkins.service",
}

#disabling setup wizard
exec { 'disable_jenkins_setup_wizard':
  command => "sed -i 's/.*JAVA_OPTS.*/Environment=\"JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false\"/' /lib/systemd/system/jenkins.service",
  require => Package['jenkins'],
  notify => [Exec['systemd-reload'],Service['jenkins']],
  path => ['/usr/bin', '/usr/sbin'],
  unless => "grep Djenkins.install.runSetupWizard=false /lib/systemd/system/jenkins.service",
}

#script to create jenkins user
file { '/tmp/create_jenkins_user.sh':
ensure => present,
owner => 'root',
group => 'root',
mode => '0755',
source => 'puppet:///modules/jenkins/create_jenkins_user.sh',
}

#Executing jenkins user creation script
exec { 'create_admin_user':
  command => "sh /tmp/create_jenkins_user.sh",
  require => [File['/tmp/create_jenkins_user.sh'],Package['jenkins']],
#  notify => Service['jenkins'],
  path => ['/usr/bin', '/usr/sbin'],
  unless => "grep -w admin1 /var/lib/jenkins/users/users.xml",
  logoutput => true,
}

#Performing cleanup of script
exec { 'cleanup':
  command => "rm /tmp/create_jenkins_user.sh",
  require => File['/tmp/create_jenkins_user.sh'],
  path => ['/usr/bin', '/usr/sbin'],
}

}
