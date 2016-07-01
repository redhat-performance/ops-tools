#!/bin/sh
# simple tool to migrate a virtual machines bridge interface
# usage: ./move-vm-bidge-interface.sh virtualmachine bridge1 bridge2
# e.g. ./move-vm-bidge-interface.sh c08-h30-vm-01 br1 br2

vmname=$1
oldbr=$2
newbr=$3

virsh destroy $vmname

tempeditor=$(mktemp /tmp/edit-vm-XXXXXX)

cat > $tempeditor <<EOF
#!/bin/sh

sed -i -e "s/$oldbr/$newbr/g" \$1
EOF

chmod 755 $tempeditor
EDITOR=$tempeditor virsh edit $vmname

virsh start $vmname
