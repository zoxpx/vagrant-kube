#!/bin/sh

if [ "x$SALT_MASTER" = x ]; then
    echo "SALT_MASTER variable not defined - skipping install of salt-client" 2>&1
    exit 0
fi

echo ":: Installing Salt-Minion (master @ ${SALT_MASTER})..."

install -o root -g root -m 755 -d /etc/salt/minion.d
echo "master: $SALT_MASTER" > /etc/salt/minion.d/99-master-address.conf

if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    echo "deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/2016.11 xenial main" >> /etc/apt/sources.list.d/saltstack.list
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E08A149DE57BFBE
    apt-get update && apt-get install -y salt-minion

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    rpm -ivh https://repo.saltstack.com/yum/redhat/salt-repo-2016.11-2.el7.noarch.rpm
    yum install -y salt-minion

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

systemctl enable salt-minion
systemctl restart salt-minion

