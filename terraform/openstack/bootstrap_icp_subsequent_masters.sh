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
    yum -y install socat 
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
    zypper -n install socat
    # Either install the icp docker version or from the repo
    if [ ${docker_download_location} != "" ]; then
        TMP_DIR="$(/bin/mktemp -d)"
        cd "$TMP_DIR"
        /usr/bin/wget -q "${docker_download_location}"
        chmod +x *
        ./*.bin --install
        /bin/rm -rf "$TMP_DIR"
    else
        zypper -n install docker
    fi
    systemctl start docker
else 
# Ubuntu specific steps
    # Disable the firewall
    /usr/sbin/ufw disable
    # Prepare the system for updates, install Docker and install Python
    /usr/bin/apt update
    # Make sure we're not running some old version of docker
    /usr/bin/apt-get --assume-yes purge docker
    /usr/bin/apt-get --assume-yes purge docker-engine
    /usr/bin/apt-get --assume-yes purge docker.io
    /usr/bin/apt-get --assume-yes install apt-transport-https \
    ca-certificates curl software-properties-common python python-pip

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

# Ensure the hostnames are resolvable
#IP=`ifconfig `ip route | grep default | head -1 | sed 's/\(.*dev \)\([a-z0-9]*\)\(.*\)/\2/g'` | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1`
IP=`/sbin/ip -4 -o addr show dev enp0s1 | awk '{split($4,a,"/");print a[1]}'`
/bin/echo "$IP $(hostname)" >> /etc/hosts
if [ "${if_HA}" == "true" ]; then
    for master_ip in $( cat /tmp/icp_master_nodes.txt | sed 's/|/\n/g' ); do
       /bin/echo "$master_ip $(hostname)" >> /etc/hosts
    done
fi

sed -i '/127.0.1.1/s/^/#/g' /etc/hosts
sed -i '/ip6-/s/^/#/g' /etc/hosts        #.....................................test it out

#cat /tmp/id_rsa.terraform >> /root/.ssh/authorized_keys

if [ "${if_HA}" == "true" ]; then
    /usr/bin/apt-get --assume-yes install nfs-common
    /bin/mkdir -p /var/lib/registry
    /bin/mkdir -p /var/lib/icp/audit
    /bin/mkdir -p /var/log/audit
    /bin/echo '${var.reg_path} ${var.registry_mount_src}  ${var.registry_mount_type}  ${var.registry_mount_options}   0 0' | sudo tee -a /etc/fstab
    /bin/echo '${var.auth_audit_path} ${var.audit_mount_src}  ${var.audit_mount_type}  ${var.audit_mount_options}   0 0' | sudo tee -a /etc/fstab
    /bin/echo '${var.kub_audit_path} ${var.kub_audit_mount_src}  ${var.kub_audit_mount_type}  ${var.kub_audit_mount_options}   0 0' | sudo tee -a /etc/fstab
    /bin/mount -a
    #/bin/mount -o tcp,mountproto=tcp,nfsvers=3 "${reg_path}" "${registry_mount_src}"
    #/bin/mount -o tcp,mountproto=tcp,nfsvers=3 "${auth_audit_path}" "${audit_mount_src}"
    #/bin/mount -o tcp,mountproto=tcp,nfsvers=3 "${kub_audit_path}" "${kub_audit_mount_src}"
fi

exit 0
