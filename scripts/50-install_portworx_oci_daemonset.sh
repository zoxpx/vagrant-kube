#!/bin/sh
# install_portworx_oci_daemonset - installs the Portworx OCI as a Kubernetes DaemonSet

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    echo ':: Installing Portworx OCI DaemonSet ...'
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl apply -f "https://install.portworx.com?c=mycluster22&k=etcd://${K8S_MASTER_IP}:2379&d=${MYVMIF}&m=${MYVMIF}&s=${MYSTORAGE}"
else
    echo '(skipping install of Portworx on this node)'
fi

