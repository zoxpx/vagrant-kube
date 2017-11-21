#!/bin/sh
# install_etcd_v3 - installs the Etcd v3 key/value database (standalone install, shared between Portworx and Kubernetes)

hostname -I | grep -wq $K8S_MASTER_IP
if [ $? -eq 0 ]; then
    echo ':: Installing Etcd k/v database ...'
    curl -fsSL https://github.com/coreos/etcd/releases/download/v3.2.6/etcd-v3.2.6-linux-amd64.tar.gz | \
	tar -xvz --strip=1 -f - -C /usr/local/bin etcd-v3.2.6-linux-amd64/etcdctl etcd-v3.2.6-linux-amd64/etcd
    useradd -d /var/lib/etcd -s /bin/false -m etcd
    cat > /lib/systemd/system/etcd.service << _eof
[Unit]
Description=etcd key-value store
After=network.target

[Service]
User=etcd
Type=notify
PermissionsStartOnly=true
Environment=ETCD_NAME=%H
EnvironmentFile=-/etc/default/%p
ExecStart=/usr/local/bin/etcd --advertise-client-urls 'http://localhost:2379,http://${K8S_MASTER_IP}:2379' --listen-client-urls 'http://0.0.0.0:2379' --data-dir /var/lib/etcd/default
Restart=on-abnormal
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
_eof
    systemctl daemon-reload
    systemctl enable etcd
    systemctl restart etcd

else
    echo '(skipping install of Etcd on this node)'
fi

