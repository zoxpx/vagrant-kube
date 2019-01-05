#!/bin/sh
# install_prereqs - should run first, install base packages and fix configuration
# DEBUG
#  - export K8S_MASTER_IP=192.168.56.70 K8S_TOKEN='030ffd.5d7a97b7e0d23ba9' K8S_CIDR=192.168.56.0/24 MYVMIF=eth1 MYSTORAGE=/dev/sdb

echo ':: Installing Prerequisites ...'
if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    apt-get clean && apt-get update
    apt-get install -y apt-transport-https lsb-release curl linux-image-$(uname -r)

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled  # VAGRANT/' /etc/selinux/config && \
	setenforce 0
    systemctl disable firewalld && systemctl stop firewalld
    yum clean all
    yum makecache all
    yum install -y curl make net-tools bind-utils epel-release e2fsprogs yum-plugin-versionlock

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

