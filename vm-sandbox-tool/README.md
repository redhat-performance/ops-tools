vm-sandbox-tool
===============
a simple tool to easily reset VMs to a vanilla state for testing/development

**Features**
  - use a qcow2 backing file to revert VM's quickly back to a vanilla state
  - ensure static, interative IP addressing on testing VMs
  - use libguestfs to inject SSH keys and network/host configuration

**Requirements**
  - libvirt
  - qemu-kvm
  - qemu-img
  - libguestfs-tools
  - virt-manager *or* virt-install
  - An EL-based Hypervisor

**Setup**
  - Install a CentOS/RHEL7/Fedora VM locally or on a Libvirt hypervisor
    - Substitute default image names below if not using CentOS7
  - Shutdown the VM
  - Delete the VM *(save the image)*
  - Rename your saved VM image to ```centos7-base.qcow2```
```
cd /var/lib/libvirt/images/
mv /var/lib/libvirt/images/centos7.qcow2 /var/lib/libvirt/images/centos7-base.qcow2
```
  - Create a number of VM qcow2 images using the above image as the backing file.

```
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-01.qcow2
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-02.qcow2
qemu-img create -b `pwd`/centos7-base.qcow2 -f qcow2 host-03.qcow2
```

**Build Test Fleet**
  - Create 3 VMs (or as many needed in your test environment) via virt-manager
    - Use the ```import existing disk image``` option for each of the above qcow2 images you just created.

![virt-manager](/shell/vm-sandbox-tool/image/virt-manager.png?raw=true)

**Download the vm-reset Script**
  - You only need ```vm-reset.sh``` so simply download it manually
```
wget https://raw.githubusercontent.com/sadsfae/misc-scripts/master/shell/vm-sandbox-tool/vm-reset.sh
```
  - Alternatively, you can clone the entire misc-scripts repo.
```
git clone https://github.com/sadsfae/misc-scripts/
cd misc-scripts/shell/vm-sandbox-tool/
```
**Prep the Tool**
  - Edit the guests array inside ```vm-reset.sh``` to your liking
    - e.g. replace host-01 with whatever hostnames you chose if it's different.
```
guests=(
   ["host-01"]="81"
   ["host-02"]="82"
   ["host-03"]="83"
   )
```
  - Insert your public SSH key in ```vm-reset.sh``` replacing the MYPUBKEY string.
    - Substitute the name of your public key below if it's not ```id_rsa.pub```
```
sed -i "s,\(.*echo.*\)ssh-rsa MYPUBKEY\(.*authorized_keys$\),\1$(cat ~/.ssh/id_rsa.pub)\2,g" ./vm-reset.sh
```
**Usage**
  - Run ```sudo ./vm-reset.sh``` to reset your environments quickly.

**Issues**
  - Occasionally you'll get a VM in a non-bootable state or grub error
    - **Fix**: Force power off and power on again.
  - Sometimes you'll see phantom libguestfs VMs show up.
    - **Fix**: Power them off and they will dissapear.
