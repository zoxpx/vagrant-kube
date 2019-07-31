#!/bin/sh
# selinux-off.sh - disables SELinux (CentOS/RHEL only), no longer needed on newer k8s/docker

echo ':: Turning off SELinux ...'
if [ -d /etc/yum.repos.d ]; then      # ------> CentOS/RHEL distro
    sed -i -e 's/^SELINUX=enforcing/SELINUX=disabled  # VAGRANT/' /etc/selinux/config && \
	setenforce 0

else    # ------------------------------------> (unsuported)
    echo '-- skipped on this platform'
fi

