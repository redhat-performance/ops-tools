# To setup ssh access to the iDRAC interfaces using ssh keys

root_pass=calvin

for mgmt in list_your_hosts_here ; do ip=$(host $mgmt | awk '{ print $NF }'); /opt/dell/srvadmin/bin/idracadm -r $ip -u root -p $root_pass sshpkauth -f ~/.ssh/id_rsa.pub -i 2 -k 1; done

# To change the root passwords
# The following examples assume you have a foreman dynamic ansible inventory installed.
# Also assume your partial host match for your iDRAC interfaces are of the form: mgmt-c.\*-h.\*.example.com

ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com"  -e "root_password=newpassword" set-root-password.yml

# To query pdisks

ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com" racadm-hwraid-query-pdisks.yml

# To query vdisks

ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*.example.com" racadm-hwraid-query-vdisks.yml

# To setup hardware raid (Do NOT do this against the foreman host)
# Use this for 2 disk systems, e.g. R630 hosts
# For the following two examples, assume your r630 dracs match the hostname form: mgmt-c.*-h.*r630.example.com

ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.\*r630.example.com" racadm-hwraid-setup-r630.yml

# To setup boot order (Do NOT do this against the foreman host)
# Use this for the R630 hosts for example

ansible-playbook -i /etc/ansible/foreman_ansible_inventory.py -l ~"mgmt-c.\*-h.t \*r630.example.com" racadm-setup-boot-r630.yml
