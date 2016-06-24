#!/bin/sh
# NOTE!!!!
# this script should be run via sudo
#
# 1) Before starting, build a centos7 VM or download a cloud image for centos7
#    and then save the base qcow2 file.  See BASE below.
#
# 2) Using virt-manager define a number of VMs (e.g. 3 VMs if that's what you
#    need).  You MUST ensure that the libvirt disk name matches the hostname,
#    e.g. host-01 uses host-01.qcow2.  This should be the default behaviour.
#
# 3) You don't need to install the OS multiple times.  Either build once if you
#    are need to customize the OS, or just use the cloud image.
#
# 4) ensure your dynamic range for libvirt does not overlap with your IPs.  On
#    a workstation or laptop, you can run :  virsh net-edit default
#    and change the range for the IPs allocated to guests.  e.g. I use:
#
#     <range start='192.168.122.101' end='192.168.122.254'/>
#
#    Note: on fedora 23 it seems 192.168.124.x/24 was used, but this may vary
#          based on your installation.
#
#    This is to allow for static IPs on the guests.
#
# 5) Once you have your guests defined, also define them in the "guests"
#    associative array (REQUIRES BASH version 4!!!).
#
# 6) Edit the script being called in chroot (see "content_update" below)
#    and add your desired SSH pubkeys for your guests.
#
# This script will reset your guests to a vanilla state.
#

# check this script for XXXXXXXXXXX (see below)
if egrep -q ".*echo.*ssh-rsa MYPUBKEY.*authorized_keys$" $0 ; then
    echo "You still have not updated this script with a valid ssh key for your guests."
    echo -n "Do you wish to continue? [y/n]"
    read answer
    if [ "$answer" != "y" -a "$answer" != "Y" ]; then
        echo consider running the following:
        echo "   sed -i \"s,\\(.*echo.*\\)ssh-rsa MYPUBKEY\\(.*authorized_keys$\\),\\1\$(cat ~/.ssh/id_rsa.pub)\\2,g\" $0"
        exit 0
    fi
fi

# determine the prefix for the libvirt network
net_prefix=$(virsh net-dumpxml default | grep range | awk -F\' '{ print $2 }' | awk -F. '{ print $1"."$2"."$3 }')

# this needs to exist in /var/lib/libvirt/images/
BASE=centos7-base.qcow2

declare -A guests
# The values are the 4th octet for the guests
# THIS SHOULD BE UPDATED TO MATCH WHAT YOU HAVE
guests=(
   ["host-01"]="81"
   ["host-02"]="82"
   ["host-03"]="83"
   )

# basic sanity checks
if [ ! -f /var/lib/libvirt/images/$BASE ]; then
    echo "Could not find /var/lib/libvirt/images/$BASE ... aborting."
    exit 1
fi

# ensure guestmount exists
if ! type -p guestmount ; then
    echo "You don't appear to have libguestfs-tools installed, citizen."
    exit 1
fi

echo "====== ensure in /etc/hosts"
for host in "${!guests[@]}" ; do
    echo "$net_prefix"."${guests["$host"]}" $host
done

function do_in_chroot {

if [ ! -d $1/tmp ]; then
  mkdir $1/tmp
fi

cat > $1/tmp/do_in_chroot.sh <<EOS
#!/bin/sh


function content_update {
    name=\$1
    octet=\$(cat /tmp/guest_octet)
    myip=${net_prefix}.\$octet

    cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE="eth0"
BOOTPROTO="static"
ONBOOT="yes"
TYPE="Ethernet"
NAME="eth0"
DEVICE="eth0"
IPADDR="\$myip"
NETMASK="255.255.255.0"
GATEWAY="${net_prefix}.1"
DNS1="${net_prefix}.1"
EOF
   echo \$name > /etc/hostname
   echo GATEWAY=${net_prefix}.1 >> /etc/sysconfig/network
   echo SELINUX=permissive > /etc/sysconfig/selinux
   echo SELINUXTYPE=targeted >> /etc/sysconfig/selinux
   mkdir /root/.ssh/
   # ADD YOUR PUB SSH KEY HERE
   echo ssh-rsa MYPUBKEY > /root/.ssh/authorized_keys
   # END SSH PUB KEY
   chmod 700 /root/.ssh
   chmod 600 /root/.ssh/authorized_keys
}

content_update \$1

EOS
chmod 755 $1/tmp/do_in_chroot.sh
echo ============================
cat $1/tmp/do_in_chroot.sh
echo ============================

}

function rebuild {
    tmpdir=$(mktemp -d /tmp/guestXXXXXXXX)

    rm -f $1.qcow2
    # create the overlay
    qemu-img create -b `pwd`/$BASE -f qcow2 $1.qcow2

    # create dir to mount the overlay and update configs
    if [ ! -d $tmpdir ]; then
        echo "Something went wrong creating $tmpdir... aborting"
        exit 1
    fi

    # mount the overlay
    guestmount -a $1.qcow2 -i --rw $tmpdir

    # create the script in $tmpdir/tmp/do_in_chroot.sh
    do_in_chroot $tmpdir

    # add all hosts to /etc/hosts in the guest
    for host in "${!guests[@]}" ; do
        echo "$net_prefix"."${guests["$host"]}" $host >> $tmpdir/etc/hosts
    done

    # store the 4th octet in chroot.  This is a hack
    echo "${guests["$1"]}" >> $tmpdir/tmp/guest_octet

    # now call the generated script in the chroot
    chroot $tmpdir /tmp/do_in_chroot.sh $1

    # now warn the user if the authorized_keys was not updated ....
    if grep -q MYPUBKEY $tmpdir/root/.ssh/authorized_keys ; then
        echo "Warning: you did not update this script to include real ssh keys in /root/.ssh/authorized_keys"
        echo "       : see the content_update function and change as needed."
    fi

    umount $tmpdir
    rmdir $tmpdir
}

# sleep for slower machines
sleep 5

cd /var/lib/libvirt/images/

for h in "${!guests[@]}" ; do
  virsh destroy $h
  rebuild $h
done

virsh net-destroy default
virsh net-start default

# sleep for slower machines
sleep 5

for h in "${!guests[@]}" ; do
  virsh start $h
done

