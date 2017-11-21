#!/bin/sh
# install_portworx_daemonset - installs the Portworx as a Kubernetes DaemoNset

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
   echo ':: Installing Portworx DaemonSet ...'
   export KUBECONFIG=/etc/kubernetes/admin.conf
   curl -o px-spec.yaml "http://install.portworx.com?cluster=mycluster&kvdb=etcd://${K8S_MASTER_IP}:2379&miface=${MYVMIF}&diface=${MYVMIF}&drives=${MYSTORAGE}"
   kubectl apply -f px-spec.yaml

else
   echo '(skipping install of Portworx on this node)'
fi

