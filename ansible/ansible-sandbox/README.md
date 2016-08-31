
ansible-sandbox
===============
Simple sandbox structure for quickly testing Ansible

**What does this do?**
   - This provides a lazy way to create a small playbook/role structure to test things

**Usage**
   - Clone the repo
```
git clone https://github.com/redhat-performance/ops-tools
cd ansible-sandbox
```
   - Edit hosts file inventory for your hosts
```
[test]
host-01
host-02
```
   - Test out anything you want in the role
```
vi install/roles/test/tasks/main.yml
```
   - Run Ansible
```
ansible-playbook -i hosts install/test.yml
```

**Example**
   - You might use this to quickly test variables, facts and other things
     without the complexity of running an entire playbook.


![testing](/ansible/ansible-sandbox/image/example.png "Common Testing Usage")

**Files**
```
├── hosts
└── install
    ├── roles
    │   └── test
    │       └── tasks
    │           └── main.yml
    └── test.yml

4 directories, 3 files
```
