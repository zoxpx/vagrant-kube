#!/bin/sh
# install_kubernetes - installs the Kubernetes cluster (first node [k8s_master_host] will be the master)
# - version check @Ubuntu: apt-cache policy kubeadm || @CentOS yum --showduplicates list kubeadm

echo ":: Installing LATEST Kubernetes ..."

if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb http://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" \
	> /etc/apt/sources.list.d/kubernetes.list
    apt-get update -q
    apt-get install -q -y kubelet kubeadm kubectl

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    cat > /etc/yum.repos.d/kubernetes.repo << _eof
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
_eof
    yum install -y kubelet kubeadm kubectl

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

# Tune OS (kubernetes prerequisites)
modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.bridge.bridge-nf-call-ip6tables=1

# Enable/Start service
systemctl enable kubelet
systemctl restart kubelet

