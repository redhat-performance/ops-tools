#!/bin/sh
# quick tool to match a host in the QUADS mongo database by switch ip address
# and physical switch interface name.
# This is particular to QUADS and our MongoDB schema
# https://github.com/redhat-performance/quads/tree/master

# print usage if not specified
if [[ $# -eq 0 ]]; then
    echo "USAGE:   ./mongo-find-host-by-sw-port.sh \$SWITCHIP \$PORT1 \$PORT2"
	echo 'EXAMPLE: ./mongo-find-host-by-sw-port.sh 10.1.40.254 "et-0/0/13:0 et-0/0/13:2"'
	echo "NOTE: You can specify one more more physical switchg interfaces"
	exit 1
fi

SWITCH=$1
INTERFACE=$2

for i in $INTERFACE ; do
mongo <<EOF
use quads
db.host.find({"interfaces": { \$elemMatch: {"ip_address": "$SWITCH", "switch_port": "$i"}}})
EOF

done | grep _id | awk -F\" '{ print $8 }'
