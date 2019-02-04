## Copy SSH Keys to Remote Systems
This is a simple playbook that copies your public SSH keys to systems assigned
to you in one of our scale/performance labs.

### Setup

* Clone Ansible repository
```
git clone https://github.com/redhat-performance/ops-tools/
cd ansible/copy-ssh-keys
```

#### Add Hosts

* Add the names of your servers to the inventory file under the cloud group like so.

```
vi hosts
```

```
[cloud]
host01.scalelab.example.com
host02.scalelab.example.com
```

* If you were using [QUADS](https://github.com/redhat-performance/quads) you might run:
```
/opt/quads/bin/quads-cli --cloud-only cloud02 >> hosts
```

#### Add SSH Keys

* By default this will copy `id_rsa.pub` found in your local user home directory where you run Ansible.

* Add any additional public SSH keys as needed
  - copy (append) your pubkey to ```install/roles/sshkeys/files/authorized_keys```
```
cat ~/.ssh/id_dsa.pub >> install/roles/sshkeys/files/authorized_keys
```

### Running the Thing

  - Run playbook, pass `-e "ansible_ssh_pass=PASSWORD"` for the default root password.
  - You should know what this is, or consult our internal FAQ documentation.

```
ansible-playbook -i hosts install/sshkeys.yml -e "ansible_ssh_pass=PASSWORD"
```

