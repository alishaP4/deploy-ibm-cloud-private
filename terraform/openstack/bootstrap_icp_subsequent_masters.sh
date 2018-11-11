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
IP=`/sbin/ip -4 -o addr show dev eth0 | awk '{split($4,a,"/");print a[1]}'`
/bin/echo "$IP $(hostname)" >> /etc/hosts

exit 0