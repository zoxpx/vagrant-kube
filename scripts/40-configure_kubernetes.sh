#!/bin/sh
# configure_kubernetes - configures and starts (or joints) the Kubernetes cluster
# - see also https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1alpha3
# - see also https://godoc.org/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta1
# - see also `kubectl -n kube-system get cm kubeadm-config -oyaml`

command -v kubeadm > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "$0: ERROR - kubeadm command not found (have you deployed Kubernetes?)" 2>&1
    exit -1
fi

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    k8sVer=$(kubectl version --short 2>&1 | awk -Fv '/Client Version: v/{print $2}' | awk -F. '{print $1*100+$2}')
    echo ":: Configuring Kubernetes Master (v$k8sVer)"
    kubeadm reset --force
    if [ $k8sVer -ge 111 ]; then
	# Kubernetes versions 1.11.x or higher, use the following kubeadm format
	cat > /etc/kubernetes/vagrant.yaml << _eof
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: $K8S_TOKEN
  ttl: "0"
  usages:
  - signing
  - authentication
localAPIEndpoint:
  advertiseAddress: $K8S_MASTER_IP
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
etcd:
  external:
    endpoints:
    - http://${K8S_MASTER_IP}:2379
networking:
  dnsDomain: cluster.local
  podSubnet: $K8S_CIDR
  serviceSubnet: 10.96.0.0/12
_eof
    else
	# Kubernetes versions 1.10.x or lower, use the following kubeadm format
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
    ## NOTE, use 'kubeadm init --kubernetes-version v1.11.3 ...'   to lock in k8s' container versions (e.g. API server)
    kubeadm init --config /etc/kubernetes/vagrant.yaml
    export KUBECONFIG=/etc/kubernetes/admin.conf
    echo "WARNING: Making $KUBECONFIG public (not reccommended for production!!)" >&2
    chmod a+r $KUBECONFIG && echo "export KUBECONFIG=$KUBECONFIG" >> /etc/profile.d/k8s_vagrant.sh
else
    echo ':: Joining Kubernetes Cluster'
    kubeadm join --token $K8S_TOKEN ${K8S_MASTER_IP}:6443 --ignore-preflight-errors=all --discovery-token-unsafe-skip-ca-verification || \
    kubeadm join --token $K8S_TOKEN ${K8S_MASTER_IP}:6443 --skip-preflight-checks --discovery-token-unsafe-skip-ca-verification
fi

