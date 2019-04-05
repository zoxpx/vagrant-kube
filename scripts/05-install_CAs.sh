#!/bin/sh
# install_CAs.sh - installs PWX_CA crtificates

# load CERT into var
CERT=$(cat << "_EOF"
-----BEGIN CERTIFICATE-----
MIID9zCCAt+gAwIBAgIFDpSL+nMwDQYJKoZIhvcNAQEFBQAwgZIxCzAJBgNVBAYT
AlVTMRMwEQYDVQQIEwpDYWxpZm9ybmlhMRIwEAYDVQQHEwlMb3MgQWx0b3MxETAP
BgNVBAoTCFBvcnR3b3J4MREwDwYDVQQLEwhQb3J0d29yeDEPMA0GA1UEAwwGUFdY
X2NhMSMwIQYJKoZIhvcNAQkBFhRzdXBwb3J0QHBvcnR3b3J4LmNvbTAeFw0xNzEy
MTQwNTU5MDBaFw0yNzEyMTQwNTU5MDBaMIGSMQswCQYDVQQGEwJVUzETMBEGA1UE
CBMKQ2FsaWZvcm5pYTESMBAGA1UEBxMJTG9zIEFsdG9zMREwDwYDVQQKEwhQb3J0
d29yeDERMA8GA1UECxMIUG9ydHdvcngxDzANBgNVBAMMBlBXWF9jYTEjMCEGCSqG
SIb3DQEJARYUc3VwcG9ydEBwb3J0d29yeC5jb20wggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDUaAUc+M/TzWrgWF7sY/rXsQvFW7wf4oTv5BUNeExWGNS2
PAaF1/a8WBNj42mKl9vnRYf+NLBEKAvQ5iz1B15G7PVcAlH9RTeNR1DUzh2htjE4
yWRgg2nhqcvL62pMzkPq8RD0DCr950EfxcIXAyvLqPOjcS2yOwDnPFN7SyGX7Kkt
W6x7FpsjIPp9uj+xbjEMdFRyy66eh9WBNEzQyuzRVYKi0Q/RLTXmhPvI1n5qSpSg
duNxTniTMPqLCIIWForPNp4SEj8d/zLwj2tHoxdaJvJ/M9sXoT80GpoW0jz+WBxH
pJlddgMzQl95V7GDn7sDrgstzK4Fb2PMH+vMKLPhAgMBAAGjUjBQMA8GA1UdEwEB
/wQFMAMBAf8wHQYDVR0OBBYEFG+RT0MYz9fINw7U8wZ9MaBsGi4BMAsGA1UdDwQE
AwIBBjARBglghkgBhvhCAQEEBAMCAAcwDQYJKoZIhvcNAQEFBQADggEBALDQTerX
yMbEDl8NCG05s1xHova5RCLVdvRUjriStJCyZ2SpdrRHCdaUa6cph8c3XPcDyrqQ
qrPXmuHoKyIsd/ERI463eO05pnwP6kqLkOe/SSjG+ybXIOigrc9OJspqGNAG2Rzk
yB0vEiZEF0uNokmzes6oFgWy5dB1nHmotVqCHyHZEHq3OhGaBXgoGsgm4AryVmBf
QZPsB18xb92C4wOiyD4FVOFNQDfbz/CdKVZSZIWCop3rSn/CpMPHBpNuec/CMf/C
nnt1PYBbMUALPeF42fICsgNNcVhEdVZGlXDL4s267fBsGAh4qqlzuqXQaJFagj9I
qCOShqZQZLHPjG0=
-----END CERTIFICATE-----
_EOF
)

echo ":: Installing PWX-CA cert ..."
if [ -d /etc/apt/sources.list.d ]; then # ----> Ubuntu/Debian distro
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -q ca-certificates

    [ ! -d /usr/share/ca-certificates/extra ] && mkdir -p /usr/share/ca-certificates/extra
    CA_FILE=/usr/share/ca-certificates/extra/PWX_ca.crt
    echo "$CERT" > $CA_FILE ; chmod 600 $CA_FILE
    CA_FILE="$(basename $CA_FILE)"
    grep -q "extra/$CA_FILE" /etc/ca-certificates.conf || echo "extra/$CA_FILE" >> /etc/ca-certificates.conf
    update-ca-certificates

elif [ -d /etc/yum.repos.d ]; then      # ----> CentOS/RHEL distro
    yum install -y ca-certificates
    update-ca-trust force-enable
    CA_FILE=/etc/pki/ca-trust/source/anchors/PWX_ca.crt
    echo "$CERT" > $CA_FILE ; chmod 600 $CA_FILE
    update-ca-trust extract

else    # ------------------------------------> (unsuported)
    echo "Your platform is not supported" >&2
    exit 1
fi

