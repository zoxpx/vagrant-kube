#!/bin/sh
#
## Kubernetes v1.8 aborts if it detectes system swap
# - can turn off via: awk '$2~/swap/{print $1}' /etc/fstab | xargs -n1 swapoff; sed -i -e 's/.*swap.*/# \0  # VAGRANT/' /etc/fstab
# - or pass '--fail-swap-on=false' in config  (which we are doing here)

kubectl version 2>/dev/null | cut -d' ' -f5 | grep -q v1.8      # GitVersion:"v1.8" ...
if [ $? -eq 0 ]; then
    CF=/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    grep -q 'Environment="KUBELET_EXTRA_ARGS=' $CF
    if [ $? -ne 0 ]; then
	sed -i '2iEnvironment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"' $CF
	systemctl daemon-reload
	systemctl restart kubelet
    fi
fi

