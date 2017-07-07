#!/bin/bash

source /home/stack/stackrc
cd /home/stack

# Utils/ dependencies

if ! rpm -q libguestfs-tools; then sudo yum install -y libguestfs-tools; fi

function apply_patch() {
  local CHANGE=$1
  local REPO=$2
  local DIR=$3
  REF=$(curl -s "https://review.openstack.org/changes/?q=change:$CHANGE&o=CURRENT_REVISION" |grep ref | head -n1 | cut -f4 -d\")
  echo "Revision for $CHANGE -> $REF"
  pushd $DIR
  git config --global user.email "michele@acksyn.org"
  git config --global user.name "Michele Baldessari"
  git fetch https://git.openstack.org/openstack/$REPO $REF && git cherry-pick FETCH_HEAD
  popd
}


# ----------- PREPARE UNDERCLOUD -----------

# undercloud: override docker config to use http rhel registries
# for importing kolla images locally and rebuild ha images
sudo sed -i 's%^INSECURE_REGISTRY=.*%INSECURE_REGISTRY="--insecure-registry 192.168.24.1:8787 --insecure-registry 192.168.24.3:8787 --insecure-registry docker-registry.engineering.redhat.com --insecure-registry brew-pulp-docker01.web.prod.ext.phx2.redhat.com:8888"%' /etc/sysconfig/docker
sudo systemctl restart docker



# ----------- PREPARE CONTAINER IMAGES -----------

# Download official OSP12 container images
wget http://download-node-02.eng.bos.redhat.com/rcm-guest/puddles/OpenStack/12.0-RHEL-7/latest_containers/container_images.yaml
sudo openstack overcloud container image upload --verbose --config-file /home/stack/container_images.yaml

#note: this works like script so comments should be commented out :)
#(rook) ^ Command fails for me : 404 Client Error: Not Found ("{"message":"no such id: docker-registry.engineering.redhat.com/rhosp12/openstack-multipathd-docker:2017-06-21.5"}")
#(zzzeek) working for me and dciabrin, is it failing on *all* lines in the file or just that one image?   e.g. paste full stdout somewhere


# ----------- PREPARE LATEST T-H-T and PUPPET DEPENDENCIES -----------

# Update to latest tripleo-heat-template
if [ -d tripleo-heat-templates ]; then rm -rf tripleo-heat-templates; fi
git clone https://github.com/openstack/tripleo-heat-templates
# Adds a docker-ha.yaml environment
apply_patch 471384 tripleo-heat-templates tripleo-heat-templates
# 2017-06-15 revert the keystone fernet changes as they require changes in
# tripleo-common that we do not have in the quickstart image that we use
pushd tripleo-heat-templates
git revert --no-edit 4ec13cc91bd9003b3baf7af140c80d517c88f868
git revert --no-edit 350e1a81dd559581bcf643e5a87ad89d6a9c0e5d
git revert --no-edit 490e237f09d2c685903b173d3fd94efc450a9cb2
popd
# add some debug logs to container deploy script
perl -pi -e 's,--verbose,--verbose --debug,g' /home/stack/tripleo-heat-templates/docker/docker-puppet.py

# Update to latest puppet-tripleo and puppet-pacemaker
if [ -d tripleo ]; then rm -rf tripleo; fi
git clone https://github.com/openstack/puppet-tripleo tripleo
# fix for stonith property being called from all the nodes
apply_patch 471630 puppet-tripleo tripleo

if [ -d pacemaker ]; then rm -rf pacemaker; fi
git clone https://github.com/openstack/puppet-pacemaker pacemaker
# 2017-06-23 dciabrin MERGED: fix for pcs bundle create mandatory argument
# apply_patch 476486 puppet-pacemaker pacemaker


# ----------- PREPARE OVERCLOUD IMAGE -----------
# sanity settings
sudo systemctl start libvirtd
sudo chown stack. overcloud-full*
tar xvf /usr/share/rhosp-director-images/ironic-python-agent.tar
tar xvf /usr/share/rhosp-director-images/overcloud-full.tar
# prepare overcloud image to use up-to-date puppet code
# and target undercloud container registry
virt-customize -v -a overcloud-full.qcow2 \
  --run-command 'sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config' \
  --run-command 'echo "INSECURE_REGISTRY='"'"'--insecure-registry 192.168.24.1:8787'"'"'" >> /etc/sysconfig/docker' \
  --delete /usr/share/openstack-puppet/modules/tripleo \
  --delete /usr/share/openstack-puppet/modules/pacemaker

# inject latest puppet-tripleo and puppet pacemaker
# latest t-h-t requires paunch to manage the containers on the nodes, install it
virt-copy-in -a overcloud-full.qcow2 tripleo pacemaker /usr/share/openstack-puppet/modules
virt-customize -a overcloud-full.qcow2 --run-command "sudo yum localinstall -y http://10.38.5.20/~dciabrin/python-paunch-1.1.1-0.20170602025340.c8e22e5.el7.centos.noarch.rpm" --selinux-relabel

# upload the new image in glance
openstack overcloud image upload --image-path . --update-existing



# ----------- PREPARE DEPLOY COMMAND LINE -----------

# OSP12 containerized services are defined in a dedicated yaml file
curl -L http://download-node-02.eng.bos.redhat.com/rcm-guest/puddles/OpenStack/12.0-RHEL-7/latest_containers/docker-osp12.yaml -o /home/stack/tripleo-heat-templates/environments/docker-osp12.yaml

# let cinder uncontainerized for HA as this is a A/P service for HA and there is no container image
# downstream as of 2017-06-01.5
sed -i 's/\(OS::TripleO::Services::Cinder.*\)/# \1/' $HOME/tripleo-heat-templates/environments/docker.yaml
sed -i 's/\(OS::TripleO::Services::Cinder.*\)/# \1/' $HOME/tripleo-heat-templates/environments/docker-ha.yaml

# composable roles: add configuration file, enable it for composable ha deplpoys
pushd /home/stack/tripleo-heat-templates/network/config/single-nic-vlans/
for i in galera rabbit remote; do
  cp controller.yaml "$i.yaml"
  #perl -pi -e 's,bridge_name,br-ex,g' "$i.yaml"
done
popd

# configuration: 3 controllers + 1 compute, no composable roles
cat > ~/customization.yaml <<EOFME
resource_registry:
  # Speed up the deployment
  OS::TripleO::Services::CeilometerAgentCentral: OS::Heat::None
  OS::TripleO::Services::CeilometerAgentNotification: OS::Heat::None
  OS::TripleO::Services::GnocchiApi: OS::Heat::None
  OS::TripleO::Services::GnocchiMetricd: OS::Heat::None
  OS::TripleO::Services::GnocchiStatsd: OS::Heat::None
  OS::TripleO::Services::AodhApi: OS::Heat::None
  OS::TripleO::Services::AodhEvaluator: OS::Heat::None
  OS::TripleO::Services::AodhNotifier: OS::Heat::None
  OS::TripleO::Services::AodhListener: OS::Heat::None
  OS::TripleO::Services::ComputeCeilometerAgent: OS::Heat::None

parameter_defaults:
  DockerNamespace: 192.168.24.1:8787/rhosp12
  DockerNamespaceIsRegistry: true
  ControllerCount: 3
  ComputeCount: 1
  CephStorageCount: 0
  NetworkerCount: 0
  ObjectStorageCount: 0
  GaleraCount: 0
  RabbitCount: 0

  OvercloudControlFlavor: controller
  OvercloudComputeFlavor: compute
EOFME

# services to enable on controller
# most of the services will be containerized based on $HOME/t-h-t/environments/docker-osp12
# currently cinder-* are not containerized because 2017-06-01.5 lack container image for that
cat > ~/custom_roles.yaml <<EOF
- name: Controller # the 'primary' role goes first
  description: |
    Controller role that has all the controler services loaded and handles
    Database, Messaging and Network functions.
  tags:
    - primary
    - controller
  networks:
    - External
    - InternalApi
    - Storage
    - StorageMgmt
    - Tenant
  CountDefault: 1
  HostnameFormatDefault: '%stackname%-controller-%index%'
  ServicesDefault:
    - OS::TripleO::Services::Pacemaker
    - OS::TripleO::Services::Ntp
    - OS::TripleO::Services::Docker
    - OS::TripleO::Services::MySQLClient
    - OS::TripleO::Services::Redis
    - OS::TripleO::Services::HAproxy
    - OS::TripleO::Services::Keystone
    - OS::TripleO::Services::GlanceApi
    - OS::TripleO::Services::CinderApi
    - OS::TripleO::Services::CinderVolume
    - OS::TripleO::Services::CinderBackup
    - OS::TripleO::Services::CinderScheduler
    - OS::TripleO::Services::HeatApi
    - OS::TripleO::Services::HeatApiCfn
    #- OS::TripleO::Services::HeatApiCloudwatch
    - OS::TripleO::Services::HeatEngine
    - OS::TripleO::Services::Iscsid
    - OS::TripleO::Services::Memcached
    - OS::TripleO::Services::Multipathd
    - OS::TripleO::Services::NeutronBgpVpnApi
    - OS::TripleO::Services::NeutronDhcpAgent
    - OS::TripleO::Services::NeutronL2gwApi
    - OS::TripleO::Services::NeutronL3Agent
    - OS::TripleO::Services::NeutronMetadataAgent
    - OS::TripleO::Services::NeutronApi
    - OS::TripleO::Services::NeutronCorePlugin
    - OS::TripleO::Services::NeutronOvsAgent
    - OS::TripleO::Services::NeutronL2gwAgent
    - OS::TripleO::Services::NovaConductor
    - OS::TripleO::Services::NovaApi
    - OS::TripleO::Services::NovaPlacement
    - OS::TripleO::Services::NovaMetadata
    - OS::TripleO::Services::NovaScheduler
    - OS::TripleO::Services::NovaConsoleauth
    - OS::TripleO::Services::NovaVncProxy
    # - OS::TripleO::Services::Ec2Api
    - OS::TripleO::Services::SwiftProxy
    - OS::TripleO::Services::ExternalSwiftProxy
    - OS::TripleO::Services::SwiftStorage
    - OS::TripleO::Services::SwiftRingBuilder
    - OS::TripleO::Services::Snmp
    - OS::TripleO::Services::Sshd
    - OS::TripleO::Services::Securetty
    - OS::TripleO::Services::Timezone
    # - OS::TripleO::Services::CeilometerAgentCentral
    # - OS::TripleO::Services::CeilometerAgentNotification
    # - OS::TripleO::Services::Horizon
    # - OS::TripleO::Services::GnocchiApi
    # - OS::TripleO::Services::GnocchiMetricd
    # - OS::TripleO::Services::GnocchiStatsd
    # - OS::TripleO::Services::ManilaApi
    # - OS::TripleO::Services::ManilaScheduler
    # - OS::TripleO::Services::ManilaBackendGeneric
    # - OS::TripleO::Services::ManilaBackendNetapp
    # - OS::TripleO::Services::ManilaBackendCephFs
    # - OS::TripleO::Services::ManilaShare
    # - OS::TripleO::Services::AodhApi
    # - OS::TripleO::Services::AodhEvaluator
    # - OS::TripleO::Services::AodhNotifier
    # - OS::TripleO::Services::AodhListener
    # - OS::TripleO::Services::SaharaApi
    # - OS::TripleO::Services::SaharaEngine
    # - OS::TripleO::Services::IronicApi
    # - OS::TripleO::Services::IronicConductor
    - OS::TripleO::Services::NovaIronic
    - OS::TripleO::Services::TripleoPackages
    - OS::TripleO::Services::TripleoFirewall
    # - OS::TripleO::Services::OpenDaylightApi
    # - OS::TripleO::Services::OpenDaylightOvs
    # - OS::TripleO::Services::SensuClient
    # - OS::TripleO::Services::FluentdClient
    # - OS::TripleO::Services::Collectd
    # - OS::TripleO::Services::BarbicanApi
    # - OS::TripleO::Services::PankoApi
    # - OS::TripleO::Services::Tacker
    # - OS::TripleO::Services::Zaqar
    # - OS::TripleO::Services::OVNDBs
    # - OS::TripleO::Services::NeutronML2FujitsuCfab
    # - OS::TripleO::Services::NeutronML2FujitsuFossw
    # - OS::TripleO::Services::CinderHPELeftHandISCSI
    # - OS::TripleO::Services::Etcd
    # - OS::TripleO::Services::AuditD
    # - OS::TripleO::Services::OctaviaApi
    # - OS::TripleO::Services::OctaviaHealthManager
    # - OS::TripleO::Services::OctaviaHousekeeping
    # - OS::TripleO::Services::OctaviaWorker
    # - OS::TripleO::Services::Vpp
    # - OS::TripleO::Services::NeutronVppAgent
    - OS::TripleO::Services::MySQL
    - OS::TripleO::Services::RabbitMQ
    - OS::TripleO::Services::Clustercheck

- name: Compute
  description: |
    Basic Compute Node role
  CountDefault: 1
  networks:
    - InternalApi
    - Tenant
    - Storage
  HostnameFormatDefault: '%stackname%-novacompute-%index%'
  disable_upgrade_deployment: True
  ServicesDefault:
    - OS::TripleO::Services::CACerts
    - OS::TripleO::Services::CertmongerUser
    #- OS::TripleO::Services::CephClient
    - OS::TripleO::Services::CephExternal

    - OS::TripleO::Services::Timezone
    - OS::TripleO::Services::Ntp
    - OS::TripleO::Services::Snmp
    - OS::TripleO::Services::Sshd
    - OS::TripleO::Services::Securetty
    - OS::TripleO::Services::NovaCompute
    - OS::TripleO::Services::NovaLibvirt
    - OS::TripleO::Services::Kernel
    - OS::TripleO::Services::ComputeNeutronCorePlugin
    - OS::TripleO::Services::ComputeNeutronOvsAgent
    - OS::TripleO::Services::ComputeCeilometerAgent
    - OS::TripleO::Services::ComputeNeutronL3Agent
    - OS::TripleO::Services::ComputeNeutronMetadataAgent
    - OS::TripleO::Services::TripleoPackages
    - OS::TripleO::Services::TripleoFirewall
    #- OS::TripleO::Services::MySQLClient
    - OS::TripleO::Services::Docker

EOF
