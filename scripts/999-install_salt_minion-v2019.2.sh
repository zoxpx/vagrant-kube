#!/bin/sh
# - install manually via: env SALT_MASTER=192.168.56.1 sudo -E bash /vagrant/scripts/999-install_salt_minion-v2016.11.sh

if [ "x$SALT_MASTER" = x ]; then
    echo "SALT_MASTER variable not defined - skipping install of salt-client" 2>&1
    exit 0
fi

echo ":: Installing Salt-Minion (master @ ${SALT_MASTER})..."

install -o root -g root -m 755 -d /etc/salt/minion.d
echo "master: $SALT_MASTER" > /etc/salt/minion.d/99-master-address.conf

if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    rele=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
    vers=$(lsb_release -rs)
    code=$(lsb_release -cs)
    if [ "x$rele" = x ] || [ "x$vers" = x ] || [ "x$code" = x ]; then
        echo "$0: ERROR -- could not get appropriate release/version/code via 'lsb_release'" >&2
        exit 1
    fi
    echo "deb http://repo.saltstack.com/apt/$rele/$vers/amd64/2019.2 $code main" > /etc/apt/sources.list.d/saltstack.list
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E08A149DE57BFBE
    apt-get update -q && apt-get install -q -y salt-minion

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    rpm -ivh https://repo.saltstack.com/yum/redhat/salt-repo-2019.2.el7.noarch.rpm
    yum install -y salt-minion

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

systemctl enable salt-minion
systemctl restart salt-minion

