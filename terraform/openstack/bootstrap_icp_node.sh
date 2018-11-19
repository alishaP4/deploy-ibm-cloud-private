#!/bin/bash

################################################################
# Module to deploy IBM Cloud Private
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Licensed Materials - Property of IBM
#
# Copyright IBM Corp. 2017.
#
################################################################

# Enable NTP
/usr/bin/timedatectl set-ntp on
# Need to set vm.max_map_count to at least 262144
/sbin/sysctl -w vm.max_map_count=262144
/bin/echo "vm.max_map_count=262144" | /usr/bin/tee -a /etc/sysctl.conf

# Now for distro dependent stuff
if [ -f /etc/redhat-release ]; then
#RHEL specific steps
        # Disable the firewall
        systemctl stop firewalld
        systemctl disable firewalld
        # Make sure we're not running some old version of docker
        yum -y remove docker docker-engine docker.io
        # Either install the icp docker version or from the repo
        if [ ${docker_download_location} != "" ]; then
            TMP_DIR="$(/bin/mktemp -d)"
            cd "$TMP_DIR"
            /usr/bin/wget -q "${docker_download_location}"
            chmod +x *
            ./*.bin --install
            /bin/rm -rf "$TMP_DIR"
        else
            yum -y install docker-ce
        fi
        systemctl start docker
elif [ -f /etc/SuSE-release ]; then
#SLES specific steps
        # Disable the firewall
        systemctl stop SuSEfirewall2
        systemctl disable SuSEfirewall2
        # Make sure we're not running some old version of docker
        zypper -n remove docker docker-engine docker.io
        # Either install the icp docker version or from the repo
        if [ ${docker_download_location} != "" ]; then
            TMP_DIR="$(/bin/mktemp -d)"
            cd "$TMP_DIR"
            /usr/bin/wget -q "${docker_download_location}"
            chmod +x *
            ./*.bin --install
            /bin/rm -rf "$TMP_DIR"
        else
            zypper -n  install docker
        fi
        systemctl start docker
else
# Ubuntu specific steps

        # Disable the firewall
        /usr/sbin/ufw disable
        # Prepare the system for updates, install Docker and install Python
        /usr/bin/apt update
        # We'll use docker-ce (vs docker.io as ce/ee is what is supported by ICP)
        # Make sure we're not running some old version of docker
        /usr/bin/apt-get --assume-yes purge docker
        /usr/bin/apt-get --assume-yes purge docker-engine
        /usr/bin/apt-get --assume-yes purge docker.io
        /usr/bin/apt-get --assume-yes install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common python-minimal

        # Either install the icp docker version or from the repo
        if [ ${docker_download_location} != "" ]; then
            TMP_DIR="$(/bin/mktemp -d)"
            cd "$TMP_DIR"
            /usr/bin/wget -q "${docker_download_location}"
            chmod +x *
            ./*.bin --install
            /bin/rm -rf "$TMP_DIR"
        else
            # Add Docker GPG key
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            # Add the repo
            /usr/bin/add-apt-repository \
            "deb https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable"
            /usr/bin/apt update
            /usr/bin/apt-get --assume-yes install docker-ce 
        fi
fi

# Ensure the hostname is resolvable
#IP=`/sbin/ip -4 -o addr show dev eth0 | awk '{split($4,a,"/");print a[1]}'` # Device "eth0" does not exist in Hursley VM's
IP=`/sbin/ip -4 -o addr show dev enp0s1 | awk '{split($4,a,"/");print a[1]}'`
#With appropriate interface observed that, the above cmd gives private ip on hursley vm's and public ip on fyre vm's.
#IP=`ifconfig `ip route | grep default | head -1 | sed 's/\(.*dev \)\([a-z0-9]*\)\(.*\)/\2/g'` | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1`
/bin/echo "$IP $(hostname)" >> /etc/hosts
if [ "${if_HA}" == "true" ]; then
    for master_ip in $( cat /tmp/icp_master_nodes.txt | sed 's/|/\n/g' ); do
       /bin/echo "$master_ip $(hostname)" >> /etc/hosts
    done
fi

sed -i '/127.0.1.1/s/^/#/g' /etc/hosts
sed -i '/ip6-/s/^/#/g' /etc/hosts

#cat /tmp/id_rsa.terraform >> /root/.ssh/authorized_keys

exit 0
