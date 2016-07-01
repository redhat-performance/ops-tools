ansible-idrac
=============

Playbook to manage idrac out-of-band interfaces with Ansible.

**What does it do?**
   - Manage Dell iDRAC interfaces with Ansible
     * Change iDRAC passwords
     * Query physical and virtual disks
     * Set up hardware RAID
     * Change NIC boot order

**Requirements**
   - iDRAC Enterprise 7+
   - Foreman [setup](https://github.com/dLobatog/foreman_ansible) with Ansible [dynamic inventory](https://github.com/theforeman/foreman_ansible_inventory/)

**Notes**
   - This assumes you have a Foreman-generated [dynamic inventory](https://github.com/theforeman/foreman_ansible_inventory/) working.
   - This assumes you have root SSH keys on the resources.

**(Setup) Deploy SSH keys on iDRAC**

Run the following to setup SSH on your iDRACS, you'll need this to proceed.

```
root_pass=calvin

for mgmt in list_your_hosts_here ; do ip=$(host $mgmt | awk '{ print $NF }'); /opt/dell/srvadmin/bin/idracadm -r $ip -u root -p $root_pass sshpkauth -f ~/.ssh/id_rsa.pub -i 2 -k 1; done
```

**Change iDRAC Passwords**

To change the root passwords on the iDRAC

```
ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com"  -e "root_password=newpassword" set-root-password.yml
```

**Querying Physical Disks**

```
ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com" racadm-hwraid-query-pdisks.yml
```

**Querying Virtual Disks**

```
ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com" racadm-hwraid-query-vdisks.yml
```

**Setup Hardware RAID**

To setup hardware raid (Do NOT do this against the foreman host)
  - Use this for 2 disk systems, e.g. R630 hosts
  - For the following two examples, assume your r630 dracs match the hostname form: mgmt-c.*-h.*r630.example.com

```
ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*r630.example.com" racadm-hwraid-setup-r630.yml
```

**Setup NIC Boot Order**

To setup boot order (Do NOT do this against the foreman host)
  - Use this for the R630 hosts for example

```
ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.t \*r630.example.com" racadm-setup-boot-r630.yml
```

