#!/bin/sh -x

if [ `id -u` -le 0 ]; then
    echo kb1 kb2 kb3 kb4 kb5 | xargs -n1 salt-key -yd
fi

#export KUBE_OSTYPE=ubuntu16
export KUBE_OSTYPE=bento16

# KB1 setup

chmod 755 scripts/10b-install_docker_native.sh
chmod 644 scripts/10a-install_docker_latest.sh

vagrant up kb1

# KB2 setup

chmod 755 scripts/10a-install_docker_latest.sh
chmod 644 scripts/10b-install_docker_native.sh

vagrant up kb2

# KB3 setup

chmod 644 scripts/10a-install_docker_latest.sh
chmod 755 scripts/10b-install_docker_native.sh

vagrant up kb3

# KB4 setup
export KUBE_OSTYPE=centos7

chmod 755 scripts/10a-install_docker_latest.sh
chmod 644 scripts/10b-install_docker_native.sh

vagrant up kb4

# KB5 setup

chmod 644 scripts/10a-install_docker_latest.sh
chmod 755 scripts/10b-install_docker_native.sh

vagrant up kb5

