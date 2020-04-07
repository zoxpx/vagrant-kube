#!/bin/sh
# - configures weave network

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    echo ':: Configuring Kubernetes Network (weave)'
    [ -f /etc/profile.d/k8s_vagrant.sh ] && . /etc/profile.d/k8s_vagrant.sh
    kubectl apply -n kube-system -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" --validate=false
fi

