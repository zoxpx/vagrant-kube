#!/bin/sh
#
## Kubernetes v1.8+ aborts if it detectes system swap
# - can turn off via: awk '$2~/swap/{print $1}' /etc/fstab | xargs -n1 swapoff; sed -i -e 's/.*swap.*/# \0  # VAGRANT/' /etc/fstab
# - or pass '--fail-swap-on=false' in config

echo ':: Turning off swap ...'

if [ `wc -l < /proc/swaps` -gt 1 ]; then
    awk '/swap/{print $1}' /etc/fstab | xargs -n1 swapoff
    sed -i -e 's/.*swap.*/# \0  # VAGRANT/' /etc/fstab
fi

