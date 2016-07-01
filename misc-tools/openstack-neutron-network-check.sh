#!/bin/bash
# nagios check script to:
# 1) spin up an instance and attach floating ip
# 2) ping the floating ip
# 3) ssh into the instance and check metadata service is working
# 4) tear down instance, record return status for pass/fail
# ** use in conjunction with openstack-neutron-network-check-wrapper.sh

# external network is: c63b3ed6-3819-48c5-a286-d8727ad8c985
# fedora image is:  2dadcc7b-3690-4a1d-97ce-011c55426477
# cirros image is:  7006f873-25ca-48c7-8817-41f29506f88b

function get_id () {
  echo `"$@" | awk '/ id / {print $4}'`
}

function get_ip_address () {
  echo `"$@" | awk '/ floating_ip_address / {print $4}'`
}

function cleanup () {
  if [ -n "$floatingip_id" ]; then
    neutron floatingip-delete "$floatingip_id" 1>/dev/null 2>&1
  fi
  echo "I deleted $vm_id" >> /var/log/vm_delete.log
  nova delete  ${vm_id} 1>/dev/null 2>&1
  exit $exitcode
}

vm_name=nagios-fip-check-$$-$(date +%s)
image='2dadcc7b-3690-4a1d-97ce-011c55426477'
flavor=m1.small

keystonerc=/etc/nagios/keystonerc_admin

source $keystonerc

exitcode=0

BOOT=$(nova boot --flavor=${flavor} --image=${image} --key-name=nagios ${vm_name} 2>&1) 
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$BOOT"
  exitcode=2
  cleanup
fi

vm_id=$(get_id nova show ${vm_name})
sleep 5

loopcount=0
while ! nova show ${vm_id} | grep 'ACTIVE' 2>&1 > /dev/null
do
  sleep 3
  loopcount=$(expr $loopcount + 1)
  if [ $loopcount -gt 200 ]; then
    # it means 10 minutes has passed
    exitcode=2
    nova delete  ${vm_id} 1>/dev/null 2>&1
    echo "Neutron ERROR: took too long to be ACTIVE"
    cleanup
  fi
done

FIP=$(neutron floatingip-create c63b3ed6-3819-48c5-a286-d8727ad8c985 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FIP"
  exitcode=2
  cleanup
fi

floatingip=$(get_ip_address echo "$FIP")
floatingip_id=$(get_id echo "$FIP")

FLOATINGIP=$(nova add-floating-ip ${vm_id} ${floatingip} 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FLOATINGIP"
  exitcode=2
  cleanup
fi

# we need to give the instance a chance to initialize, and neutron to set things up
# sleep for a bit

sleep 30

PING=$(ping -c 3 $floatingip 2>&1)
rp=$?

if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$PING"
  exitcode=2
  cleanup
fi

# now try the ssh 
# edit to your liking
SSHRESULT=$(ssh -o StrictHostKeyChecking=false -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=false -o ConnectTimeout=10 -i /var/spool/nagios/.ssh/id_rsa -q fedora@$floatingip hostname 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo "Neutron ERROR: unable to properly ssh to guest."
  exitcode=2
  cleanup
fi


FLOATINGIPRM=$(nova remove-floating-ip ${vm_id} ${floatingip} 2>&1)
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo -n "Neutron ERROR: "
  echo "$FLOATINGIPRM"
  exitcode=2
  cleanup
fi

nova delete  ${vm_id} 1>/dev/null 2>&1
rp=$?
if [[ "$rp" -ne 0 ]]
then
  echo "Neutron ERROR: Failed to delete VM"
  exitcode=2
  cleanup
fi

if [ -n "$floatingip_id" ]; then
  neutron floatingip-delete "$floatingip_id" 1>/dev/null 2>&1
  rp=$?
  if [[ "$rp" -ne 0 ]]
  then
    echo "Neutron ERROR: Failed to delete floating_ip"
    exitcode=2
    cleanup
  fi
fi

echo "Neutron OK: Floating IP responding"
exitcode=0
cleanup
