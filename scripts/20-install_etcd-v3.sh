#!/bin/sh
# install_etcd_v3 - installs the Etcd v3 key/value database (standalone install, shared between Portworx and Kubernetes)

REL=v3.3.10
DEST=/opt/etcd

if [ "x$K8S_MASTER_IP" = x ]; then
    echo ":: Skipping install of Etcd (\$K8S_MASTER_IP not defined)"
    exit 0
elif ! hostname -I | grep -wq $K8S_MASTER_IP ; then
    echo '(skipping install of Etcd on this node)'
    exit 0
fi

echo ':: Installing Etcd k/v database ...'
useradd -d $DEST -s /bin/false -m etcd
install -o etcd -g etcd -m 755 -d $DEST $DEST/bin $DEST/data

curl -fsSL https://github.com/coreos/etcd/releases/download/$REL/etcd-${REL}-linux-amd64.tar.gz | \
    tar -xvz --strip=1 -f - -C $DEST/bin etcd-${REL}-linux-amd64/etcdctl etcd-${REL}-linux-amd64/etcd
ln -sf $DEST/bin/etcdctl /usr/local/bin
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
ExecStartPre=-/usr/bin/install -o etcd -g etcd -m 755 -d $DEST/data
ExecStart=$DEST/bin/etcd --advertise-client-urls 'http://localhost:2379,http://${K8S_MASTER_IP}:2379' --listen-client-urls 'http://0.0.0.0:2379' --data-dir $DEST/data
Restart=on-abnormal
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
_eof

systemctl daemon-reload
systemctl enable etcd
systemctl restart etcd

