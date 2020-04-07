#!/bin/sh
# - configures flannel network
# - see also https://medium.com/@anilkreddyr/kubernetes-with-flannel-understanding-the-networking-part-1-7e1fe51820e4
# - requires `kubeadm init --pod-network-cidr=10.244.0.0/16`

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    echo ':: Configuring Kubernetes Network (flannel)'
    [ -f /etc/profile.d/k8s_vagrant.sh ] && . /etc/profile.d/k8s_vagrant.sh
    curl -fsSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | \
       sed -e "/        - --kube-subnet-mgr/a \        - --iface=${MYVMIF}" | kubectl apply -n kube-system --validate=false -f -
fi

