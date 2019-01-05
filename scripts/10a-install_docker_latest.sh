#!/bin/sh
# install_docker_latest - installs the latest version of Docker

echo ':: Installing Docker (latest) ...'
curl -fsSL https://get.docker.com | sh -s > /dev/null
if [ $? -ne 0 ]; then
    echo "$0: ERROR - Could not install Docker" >&2
    exit 1
fi

systemctl enable docker
systemctl start docker

