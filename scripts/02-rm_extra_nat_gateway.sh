#!/bin/sh
# rm_extra_nat_gateway - removes extra NAT gateway, so that the
#   public_network/use_dhcp_assigned_default_route=true route will work correctly

DFL_NAT_GATEWAY=10.0.2.2
[ `ip route | grep -c 'default via '` -gt 1 ] && ip route delete default via $DFL_NAT_GATEWAY

# Persist via CRON  (note: require active crond service)
echo "# VAGRANT - $0" >> /etc/crontab
echo "@reboot root sleep 20 ; [ \`ip route | grep -c 'default via '\` -gt 1 ] && ip route delete default via $DFL_NAT_GATEWAY" >> /etc/crontab

