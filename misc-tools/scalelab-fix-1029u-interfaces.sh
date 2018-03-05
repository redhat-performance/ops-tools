#!/bin/sh
# Sometimes SuperMicro 1029U systems don't get their
# internal 40GbE interface files generated via kickstart
# %post.  This fixes that for now until we can figure out
# why.
# USAGE:
# copy to affected hosts and run
# e.g.
# scp fix-post.sh b01-h01-1029u.example.com
# ssh -n b01-h01-1029u.example.com "sh -x /root/fix-post.sh"

mask2cdr ()
{
   # Assumes there's no "255." after a non-255 byte in the mask
   local x=${1##*255.}
   set -- 0^^^128^192^224^240^248^252^254^ $(( (${#1} - ${#x})*2 )) ${x%%.*}
   x=${1%%$3*}
   echo $(( $2 + (${#x}/4) ))
}


cdr2mask ()
{
   # Number of args to shift, 255..255, first non-255 byte, zeroes
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

def_interface=$(ip route  | egrep ^default | awk '{ print $5 }')
def_gateway=$(ip route  | egrep ^default | awk '{ print $3 }')
#def_network=$(ip route  | egrep -v ^default | grep $def_interface | grep -v 169.254 | awk '{ print $1 }')
def_address=$(ip a show $def_interface | grep "inet " | awk '{ print $2 }'| awk -F/ '{ print $1 }')
def_network_address=$(netstat -rn | egrep -v 'Destination|169.254|^0.0.0.0|^Kernel'  | grep $def_interface | awk '{ print $1 }')
#def_network_cidr=$(echo $def_network | awk -F/ '{ print $2 }')
def_network_netmask=$(netstat -rn | egrep -v 'Destination|169.254|^0.0.0.0|^Kernel' | grep $def_interface | awk '{ print $3 }' | grep -v 255.255.255.255 )

# setup em1, em2, em3, and em4 and also ens3f0/1 or ens5f0/1 === WIP
o3=$(echo $def_address | awk -F. '{ print $3 }')
# use pipe awk line here as 4th octect, carriage return cause render issues
o4=$(echo $def_address | awk -F. '{ print $4 }' | awk '{ print $1 }')

# if the host has p2p1 and is an r620 ... use them


rm -f /etc/sysconfig/network-scripts/ifcfg-eno2*

if ip a show enp175s0f0 1>/dev/null 2>&1 ; then
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f0 <<EOF
DEVICE=enp175s0f0
NAME=enp175s0f0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.16.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f0.101 <<EOF
DEVICE=enp175s0f0.101
NAME=enp175s0f0.101
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.20.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f0.200 <<EOF
DEVICE=enp175s0f0.200
NAME=enp175s0f0.200
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.24.$o3.$o4
NETMASK=255.252.0.0
EOF

fi

if ip a show enp175s0f1 1>/dev/null 2>&1 ; then
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f1 <<EOF
DEVICE=enp175s0f1
NAME=enp175s0f1
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.17.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f1.102 <<EOF
DEVICE=enp175s0f1.102
NAME=enp175s0f1.102
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.21.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp175s0f1.200 <<EOF
DEVICE=enp175s0f1.200
NAME=enp175s0f1.200
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.25.$o3.$o4
NETMASK=255.252.0.0
EOF

fi

if ip a show enp216s0f0 1>/dev/null 2>&1 ; then
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f0 <<EOF
DEVICE=enp216s0f0
NAME=enp216s0f0
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.18.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f0.103 <<EOF
DEVICE=enp216s0f0.103
NAME=enp216s0f0.103
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.22.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f0.200 <<EOF
DEVICE=enp216s0f0.200
NAME=enp216s0f0.200
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.26.$o3.$o4
NETMASK=255.252.0.0
EOF

fi

if ip a show enp216s0f1 1>/dev/null 2>&1 ; then
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f1 <<EOF
DEVICE=enp216s0f1
NAME=enp216s0f1
TYPE=Ethernet
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.19.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f1.104 <<EOF
DEVICE=enp216s0f1.104
NAME=enp216s0f1.104
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.23.$o3.$o4
NETMASK=255.255.0.0
EOF
cat > /etc/sysconfig/network-scripts/ifcfg-enp216s0f1.200 <<EOF
DEVICE=enp216s0f1.200
NAME=enp216s0f1.200
VLAN=yes
BOOTPROTO=static
DEFROUTE=no
ONBOOT=yes
IPADDR=172.27.$o3.$o4
NETMASK=255.252.0.0
EOF

fi

for i in enp175s0f0 enp175s0f0.101 enp175s0f0.200 enp175s0f1 enp175s0f1.102 enp175s0f1.200 enp216s0f0 enp216s0f0.103 enp216s0f0.200 enp216s0f1 enp216s0f1.104 enp216s0f1.200 ; do ifup $i ; done
