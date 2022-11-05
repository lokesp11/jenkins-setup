#!/bin/sh

if sudo dpkg -l puppet > /dev/null; then
	echo "Puppet is already installed, skipping puppet installation"
	#exit 0
else
	ID=$(cat /etc/os-release | awk -F= '/^ID=/{print $2}' | tr -d '"')
	case "${ID}" in
		ubuntu)
			wget --dns-timeout=10 --connect-timeout=10 https://apt.puppetlabs.com/puppet6-release-focal.deb
			sudo dpkg -i puppet6-release-focal.deb
			sudo apt-get update -y
			sudo apt-get install puppet-agent -y
			sudo systemctl start puppet
			sudo systemctl enable puppet
			;;
		*)
			echo "OS '${ID}' not supported" 2>&1
			exit 1
			;;
	esac
fi

if [ -d "/tmp/jenkins-repo/" ]; then
    sudo rm -rf /tmp/jenkins-repo/
fi    
sudo mkdir -p /tmp/jenkins-repo/
sudo git clone https://github.com/lokesp11/jenkins-setup.git /tmp/jenkins-repo/
echo "copying jenkins module and manifests"
sudo cp -R /tmp/jenkins-repo/non-vagrant-setup/modules/jenkins /etc/puppetlabs/code/environments/production/modules/
sudo cp -R /tmp/jenkins-repo/non-vagrant-setup/manifests/* /etc/puppetlabs/code/environments/production/manifests/
echo "deleting temp files"
sudo rm -rf /tmp/jenkins-repo/

echo "Setting Jenkins"
sudo /opt/puppetlabs/bin/puppet apply /etc/puppetlabs/code/environments/production/manifests/node.pp --test
