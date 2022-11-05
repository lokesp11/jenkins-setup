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
if [ -d "/tmp/vagrant-tmp/" ]; then
	echo "copying jenkins module and manifests"
	sudo cp -R /tmp/vagrant-tmp/modules/jenkins /etc/puppetlabs/code/environments/production/modules/
	sudo cp -R /tmp/vagrant-tmp/manifests/* /etc/puppetlabs/code/environments/production/manifests/
	echo "deleting temp files"
	sudo rm -rf /tmp/vagrant-tmp
else
	echo "puppet code was not found on locals system"
fi
