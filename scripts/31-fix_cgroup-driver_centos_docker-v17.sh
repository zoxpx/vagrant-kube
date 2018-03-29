#!/bin/sh
# Fix CentOS service hang on Docker v1.13+ (see https://github.com/kubernetes/kubeadm/issues/228)

docker --version | grep -qw 17
if [ $? -eq 0 ]; then
    CF=/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    grep -q -- --cgroup-driver=systemd $CF
    if [ $? -eq 0 ]; then
	sed -i -e 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/' $CF
	systemctl daemon-reload
	systemctl restart kubelet
    fi
fi

