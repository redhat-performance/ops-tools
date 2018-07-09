#!/bin/sh
#
# Cleanup validation interface configs
#
# This removes the auto-deployed /etc/sysconfig/network/scripts/ifcfg-*
# files for internal RFC1918 interfaces that start with 172.x that
# we drop down after systems are provisioned.
########### to just disable the interfaces
# ./cleanup-interfaces.sh --disable
########### to remove the interfaces
# ./cleanup-interfaces.sh --nuke

# print usage if not specified
if [[ $# -eq 0 ]]; then
    echo "USAGE:"
    echo "./cleanup-interfaces.sh --disable"
    echo "./cleanup-interfaces.sh --nuke"
    exit 1
fi

mode=$1
disable=false
nuke=false

if [ "$mode" == "--disable" ]; then
  disable=true
fi

if [ "$mode" == "--nuke" ]; then
  nuke=true
fi

filelist="$(grep IPADDR=172 /etc/sysconfig/network-scripts/* | awk -F: '{ print $1 }')"

if $disable ; then
  for f in $filelist ; do
    ifdown $(basename $f | awk -F- '{ print $2 }')
    sed -i -e 's/ONBOOT=yes/ONBOOT=no/g' $f
  done
fi

if $nuke ; then
  for f in $filelist ; do
    ifdown $(basename $f | awk -F- '{ print $2 }')
    rm -f $f
  done
fi
