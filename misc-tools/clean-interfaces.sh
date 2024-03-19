#!/bin/sh
#
# Cleanup validation interface configs
#
# This removes the auto-deployed /etc/sysconfig/network/scripts/ifcfg-*
# files for internal RFC1918 interfaces that start with 172.x that
# we drop down after systems are provisioned.
########### to just disable the interfaces
# ./clean-interfaces.sh --disable
########### to remove the interfaces
# ./clean-interfaces.sh --nuke

# print usage if not specified
if [[ $# -eq 0 ]]; then
    echo "USAGE:"
    echo "./clean-interfaces.sh --disable"
    echo "./clean-interfaces.sh --nuke"
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

if [ $(rpm --eval "%{lua:print(rpm.vercmp($(rpm -qf /etc/redhat-release --queryformat '%{VERSION}\n'), '9.0'))}") -lt 0 ]; then

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

else
    alluuids=$(nmcli -g uuid c show)
    uuidlist=$(for uuid in $alluuids ; do (nmcli c show $uuid | grep ipv4.address | awk '{ print $NF }') | grep -E -q ^172. && echo $uuid ; done)
    for uuid in $uuidlist ; do
        if $disable ; then
            /usr/bin/nmcli connection down $uuid
            /usr/bin/nmcli connection modify $uuid autoconnect false
        fi

        if $nuke ; then
            /usr/bin/nmcli connection down $uuid
            /usr/bin/nmcli connection delete $uuid
        fi
    done
fi
