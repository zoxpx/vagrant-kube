#!/bin/sh
# install_docker_native - installs the platform's "native" version of Docker

echo ':: Installing Docker (native) ...'

if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    dpkg --purge docker-ce
    apt-get install -y docker.io

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    yum install -y docker

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

sed -i -e 's/^MountFlags=slave/# \0  # VAGRANT/' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable docker
systemctl restart docker

