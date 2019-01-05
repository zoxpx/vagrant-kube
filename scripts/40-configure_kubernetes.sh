#!/bin/sh
# configure_kubernetes - configures and starts (or joints) the Kubernetes cluster
# - see also https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1alpha3

command -v kubeadm > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "$0: ERROR - kubeadm command not found (have you deployed Kubernetes?)" 2>&1
    exit
fi

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    k8sVer=$(kubectl version --short 2>&1 | awk -Fv '/Client Version: v/{print $2}' | awk -F. '{print $1*100+$2}')
    echo ":: Configuring Kubernetes Master (v$k8sVer)"
    kubeadm reset --force
    if [ "x$k8sVer" != x ] && [ $k8sVer -ge 113 ]; then
	# Kubernetes versions 1.13.x or higher, use the following kubeadm format
	cat > /etc/kubernetes/vagrant.yaml << _eof
apiVersion: kubeadm.k8s.io/v1alpha3
kind: InitConfiguration
bootstrapTokens:
- token: "030ffd.5d7a97b7e0d23ba9"
  description: "kubeadm bootstrap token"
  ttl: "24h"
apiEndpoint:
  advertiseAddress: "$K8S_MASTER_IP"
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
etcd:
  external:
    endpoints:
    - "http://${K8S_MASTER_IP}:2379"
networking:
  podSubnet: "$K8S_CIDR"
_eof
    else
	# Kubernetes versions 1.12.x or lower, use the following kubeadm format
	cat > /etc/kubernetes/vagrant.yaml << _eof
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
api:
  advertiseAddress: $K8S_MASTER_IP
etcd:
  endpoints:
  - http://${K8S_MASTER_IP}:2379
token: $K8S_TOKEN
networking:
  podSubnet: $K8S_CIDR
_eof
    fi
    kubeadm init --config /etc/kubernetes/vagrant.yaml
    kubeadm token create $K8S_TOKEN --ttl 0
    export KUBECONFIG=/etc/kubernetes/admin.conf
    echo "WARNING: Making $KUBECONFIG public (not reccommended for production!!)" >&2
    chmod a+r $KUBECONFIG && echo "export KUBECONFIG=$KUBECONFIG" >> /etc/profile.d/k8s_vagrant.sh

    echo ':: Configuring Kubernetes Network'
    kubectl apply -n kube-system -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')" --validate=false

else
    echo ':: Joining Kubernetes Cluster'
    #kubeadm join --token $K8S_TOKEN ${K8S_MASTER_IP}:6443 --skip-preflight-checks --discovery-token-unsafe-skip-ca-verification
    kubeadm join --token $K8S_TOKEN ${K8S_MASTER_IP}:6443 --ignore-preflight-errors=all --discovery-token-unsafe-skip-ca-verification
fi

