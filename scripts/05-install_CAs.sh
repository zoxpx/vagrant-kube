#!/bin/sh
# install_CAs.sh - installs CA crtificates (if any)

if [ "x$CAfile" = x ] || [ ! -f "$CAfile" ] ; then
    echo "CAfile variable not defined - skipping install of CA certs" 2>&1
    exit 0
fi

echo ':: Installing CA cert $CAfile ...'
if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    [ ! -d /usr/share/ca-certificates/extra ] && mkdir -p /usr/share/ca-certificates/extra
    cp "$CAfile" /usr/share/ca-certificates/extra/
    CAfile="$(basename $CAfile)"
    grep -q "extra/$CAfile" /etc/ca-certificates.conf
    [ $? -ne 0 ]; echo "extra/$CAfile" >> /etc/ca-certificates.conf
    update-ca-certificates

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    yum install -y ca-certificates
    update-ca-trust force-enable
    cp "$CAfile" /etc/pki/ca-trust/source/anchors/
    update-ca-trust extract

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi
