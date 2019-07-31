#!/bin/sh
#

MACS=$*

for i in $MACS ; do
mongo <<EOF
use quads
db.host.find({"interfaces": { \$elemMatch: {"mac_address": "$i"}}})
EOF

done | grep _id | awk -F\" '{ print $8 }'
