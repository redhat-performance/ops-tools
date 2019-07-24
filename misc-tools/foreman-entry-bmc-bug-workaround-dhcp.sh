#!/bin/sh
#
# 1) remove foreman sub-interfaces that are bmc devices
# 2) re-add them as proper bmc devices
# 3) re-adding forces dhcpd.leases update where some were missing.
#
# this works around a Foreman API bug we found when trying to restore
# (re-define) BMC / OOB DHCP entries in Foreman that were removed by sync
# problems between dhcpd and foreman-proxy introduced while trying to accomodate
# a workaround for CoreOS.
#
# Bug description:  The foreman-proxy API returns a 200 when running 'hammer
# host interface create' but fails silently when the subnet_id parameter isn't
# passed.  The end result is that foreman-proxy never writes to the dhcpd.leases
# file.

# Because we don't know the subnet_id of entries that are missing as they've
# been deleted, but we do know the IP address we have to compare what ipcalc
# tells us is the subnet_id then pass that in to successfully complete the
# command.
#
# note this also sets up proper ipmi/bmc functionality through Foreman UI now.
#
# 12:03 wfoster: hammer host info --name f10-h29-b01-5039ms.rdu2.example.com | grep Id | grep "2)" | awk '{print $3}'
# 12:03 wfoster: hammer host interface delete --host f10-h29-b01-5039ms.rdu2.example.com --id 1681
# 12:03 wfoster: hammer host interface create --host f10-h29-b01-5039ms.rdu2.example.com --type bmc --provider IPMI --mac ac:1f:6b:75:a9:77 --ip 10.1.33.27 --name mgmt-f10-h29-b01-5039ms.rdu2.example.com --username=root --password=XXXXXXX
#
#---|------------|--------------|----------------|---------------|---------|----------
#ID | NAME       | NETWORK ADDR | NETWORK PREFIX | NETWORK MASK  | VLAN ID | BOOT MODE
#---|------------|--------------|----------------|---------------|---------|----------
#2  | rdu2_util  | 10.1.36.0    | 22             | 255.255.252.0 |         | DHCP
#1  | rdu2_mgmt  | 10.1.32.0    | 23             | 255.255.254.0 |         | DHCP
#3  | rdu2_mgmt2 | 10.1.40.0    | 23             | 255.255.254.0 |         | DHCP
#4  | rdu2_mgmt3 | 10.1.42.0    | 23             | 255.255.254.0 |         | DHCP
#5  | rdu2_mgmt4 | 10.1.44.0    | 23             | 255.255.254.0 |         | DHCP
#---|------------|--------------|----------------|---------------|---------|----------

# Usage: foreman-entry-bmc-bug-workaround-dhcp.sh HOSTNAME_MISSING_IPMI | tee -a ~/host-results.log

host=$1

id=$(hammer host info --name $host | grep "2) Id:" | awk '{ print $3 }')
mac=$(hammer host info --name $host | grep -A4 "2) Id:" | grep MAC | awk '{ print $NF }')
ip=$(hammer host info --name $host | grep -A5 "2) Id:" | grep -i ip | awk '{ print $NF }')
subnet=$(ipcalc -n $ip/23 | awk -F= '{ print $2 }')
subnet_id=$(hammer subnet list | grep $subnet | awk '{ print $1 }')

echo deleting interface for $host - mac = $mac - ip = $ip

hammer host interface delete --host $host --id $id
hammer host interface create --host $host --type bmc --provider IPMI --mac $mac --subnet-id $subnet_id --ip $ip --name mgmt-$host --username root --password=XXXXXXX
