#!/bin/bash
# Simple tool to create a bridged interface on a host.
# assumes you're running a Red Hat based distribution
# requires net-tools, bridge-utils
# Warning: this relies on the legacy 'network'
# service, if you are using NetworkManager it will be
# stopped and disabled.

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

# check that we have the right tools installed first.
nettoolsinstalled=`rpm -qa | grep net-tools |wc -l`
bridgeutilsinstalled=`rpm -qa | grep bridge-utils | wc -l`
networkscriptsinstalled=`rpm -qa | grep network-scripts | head -n1 | wc -l`
check_nettools() {
	echo "checking for net-tools.."
	if [[ $nettoolsinstalled = '0' ]]
	then
		echo "net-tools not installed.. installing"
		yum install net-tools -y >/dev/null 2>&1
        else
        echo "[OK]"
    fi
}

check_bridgeutils() {
	echo "checking for bridge-utils.."
	if [[ $bridgeutilsinstalled = '0' ]]
	then
		echo "bridge-utils not installed.. installing"
		yum install bridge-utils -y >/dev/null 2>&1
        else
        echo "[OK]"
    fi
}

check_netscripts() {
	echo "checking for network-scripts.."
	if [[ $networkscriptsinstalled = '0' ]]
	then
		echo "bridge-utils not installed.. installing"
		yum install network-scripts -y >/dev/null 2>&1
        else
        echo "[OK]"
    fi
}
# check net-tools and bridge-utils first
check_nettools
check_bridgeutils
check_netscripts

# check if NetworkManager is running/enabled
nm_on=`systemctl status NetworkManager | grep running | wc -l`

if [[ $nm_on -eq 1 ]]; then
    # gather and print some interface info.
nmcli_active_con=`/usr/bin/nmcli con show | egrep "ethernet" | awk '{print $1}' | head -n1`
nmcli_ip_addr=`/usr/bin/nmcli con show $nmcli_active_con | grep "IP4.ADDRESS\[1\]:" | awk '{print $2}'`
nmcli_gateway=`/sbin/route -n | grep UG | awk '{print $2}' | head -n1`
nmcli_dns1=`cat /etc/resolv.conf | grep nameserver | head -n1 | awk '{print $2}'`

    echo "Your current NetworkManager connection: $nmcli_active_con"
    echo "Your current IP address: $nmcli_ip_addr"
    echo "Your current Gatway: $nmcli_gateway"
    echo "Your DNS server:  $nmcli_dns1"
    echo "Using nmcli to set a static IP address..."
    # use NetworkManager to create our static IP config
    /usr/bin/nmcli con mod $nmcli_active_con ipv4.addresses $nmcli_ip_addr
    /usr/bin/nmcli con mod $nmcli_active_con ipv4.method manual
    /usr/bin/nmcli con mod $nmcli_active_con ipv4.addresses $nmcli_ip_addr
    /usr/bin/nmcli con mod $nmcli_active_con ipv4.gateway $nmcli_gateway
    /usr/bin/nmcli con mod $nmcli_active_con ipv4.dns $nmcli_dns1
    /usr/bin/nmcli con mod $nmcli_active_con connection.autoconnect yes
    /usr/bin/nmcli con up $nmcli_active_con
    sed -i 's/BOOTPROTO=.*$/BOOTPROTO=static/g' /etc/sysconfig/network-scripts/ifcfg-$ethname
    echo "Disabling NetworkManager for ifcfg-$ethname script"
    /usr/bin/systemctl stop NetworkManager >/dev/null 2>&1
    /usr/bin/systemctl disable NetworkManager >/dev/null 2>&1
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
   sed -i "s/DEVICE=.*$/DEVICE=$bridgename/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i 's/UUID/#UUID/g' /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i "s/NAME=$ethname/NAME=$bridgename/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i "s/NAME=.*$/NAME=$bridgename/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i "s/TYPE=Ethernet/TYPE=Bridge/g" /etc/sysconfig/network-scripts/ifcfg-$bridgename
   sed -i 's/TYPE="Ethernet"/TYPE=Bridge/g' /etc/sysconfig/network-scripts/ifcfg-$bridgename
   echo "BRIDGE=$bridgename" >> /etc/sysconfig/network-scripts/ifcfg-$ethname
   echo "Restarting Network with new Bridge .. this may take a while"
   /sbin/service network restart >/dev/null 2>&1
   /usr/bin/systemctl enable network  >/dev/null 2>&1
   echo "External Bridge: $bridgename created"
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
