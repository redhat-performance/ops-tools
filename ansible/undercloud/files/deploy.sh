#!/usr/bin/env bash
date -u

##################################
# Typical deployment (Controllers And Computes)
# time openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6

# Modifing roles_data.yaml
# time openstack overcloud deploy --templates -r /home/stack/templates/roles_data.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6

# SSL/TLS Public Endpoints (Typical)
# time openstack overcloud deploy --templates -e /home/stack/templates/enable-tls.yaml -e /home/stack/templates/inject-trust-anchor.yaml -e /home/stack/templates/cloudname.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-dns.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6

# SSL/TLS Public Endpoints (Modify roles_data.yaml)
# time openstack overcloud deploy --templates -r /home/stack/templates/roles_data.yaml -e /home/stack/templates/enable-tls.yaml -e /home/stack/templates/inject-trust-anchor.yaml -e /home/stack/templates/cloudname.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-dns.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6

##################################
# Using Scheduler-hints.yaml:
# Set your Controllers:
# openstack baremetal node set --property capabilities='node:controller-0' <ironic-uuid>
# openstack baremetal node set --property capabilities='node:controller-1' <ironic-uuid>
# openstack baremetal node set --property capabilities='node:controller-2' <ironic-uuid>
# Set computes like above:
# openstack baremetal node set --property capabilities='node:novacompute-0' <ironic-uuid>
# ...
# Set cephstorage nodes (If you have any):
# openstack baremetal node set --property capabilities='node:cephstorage-0' <ironic-uuid>
# ...
# Set objectstorage nodes (If you have any):
# openstack baremetal node set --property capabilities='node:objectstorage-0' <ironic-uuid>
# ...
# Set blockstorage nodes (If you have any):
# openstack baremetal node set --property capabilities='node:blockstorage-0' <ironic-uuid>

# Typical deployment (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /home/stack/templates/scheduler-hints.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6 --control-flavor baremetal --compute-flavor baremetal

# SSL/TLS Public Endpoints (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /home/stack/templates/scheduler-hints.yaml -e /home/stack/templates/enable-tls.yaml -e /home/stack/templates/inject-trust-anchor.yaml -e /home/stack/templates/cloudname.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/tls-endpoints-public-dns.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6 --control-flavor baremetal --compute-flavor baremetal

# With CephStorage (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /home/stack/templates/scheduler-hints.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/templates/storage-environment.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6 --ceph-storage-scale 4 --control-flavor baremetal --compute-flavor baremetal --ceph-storage-flavor baremetal

# With ObjectStorage (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /home/stack/templates/scheduler-hints.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 3 --compute-scale 6 --swift-storage-scale 4 --control-flavor baremetal --compute-flavor baremetal --swift-storage-flavor baremetal
# * Edit role_data.yml to remove swift storage off controllers (Especially if the disk count does not match)

# With BlockStorage (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /home/stack/templates/scheduler-hints.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1 --block-storage-scale 1 --control-flavor baremetal --compute-flavor baremetal --block-storage-flavor  baremetal

# All Node Types (w/ scheduler-hints.yaml)
# time openstack overcloud deploy --templates -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/puppet-pacemaker.yaml -e /home/stack/templates/storage-environment.yaml -e /home/stack/tunings.yaml --libvirt-type=kvm --ntp-server 0.pool.ntp.org --neutron-network-type vxlan --neutron-tunnel-types vxlan --control-scale 1 --compute-scale 1 --block-storage-scale 1 --swift-storage-scale 1 --ceph-storage-scale 1 --control-flavor baremetal --compute-flavor baremetal --block-storage-flavor  baremetal --swift-storage-flavor baremetal --ceph-storage-flavor baremetal
# * Edit role_data.yml to remove swift storage off controllers (Especially if the disk count does not match)

# OSP12 Pike Docker Containers Deployment (w/ scheduler-hints.yaml, storage-environment.yaml, ceph-ansible, docker_registry.yaml, deploy.yaml)
time openstack overcloud deploy --templates /usr/share/openstack-tripleo-heat-templates/ -e /home/stack/templates/scheduler-hints.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/docker.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/docker-ha.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml -e /home/stack/templates/network-environment.yaml -e /home/stack/templates/storage-environment.yaml -e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml -e /home/stack/docker_registry.yaml -e /home/stack/templates/deploy.yaml --ntp-server 0.pool.ntp.org | tee -a /home/stack/deploy-0.log

date -u
