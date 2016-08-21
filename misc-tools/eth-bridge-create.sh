#!/bin/bash
# quickly make a static ethernet interface bridged
# assumes you are using a static IP address
# assumes you're running a Red Hat based distribution
# requires net-tools

# set eth device and bridge as input variables
ethname=$1
bridgename=$2

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE:   ./eth-bridge-create.sh \$ETHDEVICE \$BRIDGENAME"
	echo "EXAMPLE: ./eth-bridge-create.sh eth0 br0"
	echo "                                      "
	exit 1
fi

# check to ensure user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# check if IP address is static
static=`cat /etc/sysconfig/network-scripts/ifcfg-$ethname | grep \
	-i static | wc -l`
if [[ $static -eq 1 ]]; then
	echo "Static IP addressing detected, proceeding.."
	else
		echo "No Static IP address detected, quitting!"
	        exit 1
	fi

# check that we have the right tools installed first.
nettoolsinstalled=`rpm -qa | grep net-tools |wc -l`
check_nettools() {
	echo "checking package dependencies.."
	if [[ $nettoolsinstalled = '0' ]]
	then
		echo "net-tools not installed.. installing"
		yum install net-tools -y >/dev/null 2>&1
        else
                echo "[OK]"
        fi
}

# check net-tools package installed first
check_nettools

check_br_exist()
{  # check if there's a bridged interface
   /sbin/ifconfig -a | grep $bridgename | egrep -v "virb" | wc -l
}

create_br_int()
{  # bring up bridged interface, make primary
   cp /etc/sysconfig/network-scripts/ifcfg-$ethname /etc/sysconfig/network-scripts/ifcfg-$bridgename 
   sed -i 's/IPADDR/#IPADDR/g' /etc/sysconfig/network-scripts/ifcfg-$ethname
   sed -i 's/NETMASK/#NETMASK/g' /etc/sysconfig/network-scripts/ifcfg-$ethname
   sed -i 's/GATEWAY/#GATEWAY/g' /etc/sysconfig/network-scripts/ifcfg-$ethname
   sed -i "s/DEVICE=$ethname/DEVICE=$bridgename/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i 's/UUID/#UUID/g' /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i "s/NAME=$ethname/NAME=$bridgename/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i "s/TYPE=Ethernet/TYPE=Bridge/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   echo "BRIDGE=$bridgename" >> /etc/sysconfig/network-scripts/ifcfg-$ethname
   echo "Restarting Network with new Bridge"
   /sbin/service network restart >/dev/null 2>&1
   echo "External Bridge: $bridgename created"
   /sbin/ifup $bridgename
   /sbin/ifconfig $bridgename
   echo "Note:: If you see issues with routing you may need to reboot"
}

# create bridge if it doesn't exist
br_exist=$(check_br_exist)

case $br_exist in
'1')
   echo "external bridge interface exists, quitting"
   exit 1
;;
'0')
   echo "external bridge interface doesn't seem to exist."
   create_br_int
;;
esac
