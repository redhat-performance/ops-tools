#!/bin/bash
# wrapper for nagios or another alerting system
# checks floating ip, allocation pool, ssh to instance, icmp
# and that metadata-agent is passing along keys properly
# ** use with openstack-neutron-network-check.sh
# ** note: it's better to have nagios or your monitoring system
#    check a status code rather than do too much lifting
#  ** you can run this out of cron
checker=/root/neutron-network-check-with-ssh
resultfile=/etc/nagios/data/floating-ip-results
TMPFILE=$(mktemp /tmp/fip-checker-XXXXXX)

$checker 1>$TMPFILE 2>&1
rp=$?
echo $rp >> $TMPFILE
cat $TMPFILE > $resultfile
rm -f $TMPFILE

