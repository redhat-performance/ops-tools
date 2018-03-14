#!/usr/bin/env python
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

import os
import sys
import time
import yaml

from ironicclient import client

start_time = time.time()

pin_yaml = sys.argv[1]
print "INFO :: Opening {} for node ipmi to node id definition".format(pin_yaml)
print "----------------------------------------------"

# Open file containing node ipmi address string to node id definition
with open(pin_yaml, "r") as stream:
    pins = yaml.load(stream)

if 'OS_PROJECT_NAME' in os.environ:
    project_name = os.environ['OS_PROJECT_NAME']
elif 'OS_TENANT_NAME' in os.environ:
    project_name = os.environ['OS_TENANT_NAME']
else:
    print 'ERROR :: Missing OS_PROJECT_NAME or OS_TENANT_NAME in rc file'
    exit(1)

user_domain_name = None
if 'OS_USER_DOMAIN_NAME' in os.environ:
    user_domain_name = os.environ['OS_USER_DOMAIN_NAME']
project_domain_name = None
if 'OS_PROJECT_DOMAIN_NAME' in os.environ:
    project_domain_name = os.environ['OS_PROJECT_DOMAIN_NAME']

# Establish Ironic API Connection
ironic = client.get_client(
        1, os_username=os.environ['OS_USERNAME'], os_password=os.environ['OS_PASSWORD'],
        os_auth_url=os.environ['OS_AUTH_URL'], os_project_name=project_name,
        os_user_domain_name=user_domain_name, os_project_domain_name=project_domain_name)

nodes = ironic.node.list()
missing = []
for node in nodes:
    ipmi_addr = ironic.node.get(node.uuid).to_dict()['driver_info']['ipmi_address']
    print "INFO :: UUID: {}, IPMI Address: {}".format(node.uuid, ipmi_addr)
    for pin in pins:
        if pin in ipmi_addr:
            print "INFO :: Found {} in {}, setting to: {}".format(pin, ipmi_addr, pins[pin])
            capablities_value = "node:{},cpu_vt:true,cpu_hugepages:true,boot_option:local," \
                "cpu_txt:true,cpu_aes:true,cpu_hugepages_1g:true,boot_mode:bios".format(pins[pin])
            patch = [
                {
                    "op": "replace",
                    "path": "/properties/capabilities",
                    "value": capablities_value,
                }
            ]
            ironic.node.update(node.uuid, patch=patch)
            del pins[pin]
            break
    else:
        print "WARNING :: Could not find: {} in {}".format(ipmi_addr, pin_yaml)
        missing.append(ipmi_addr)

print "-------------------------------------------"
print "INFO :: Took {} to pin nodes.".format(round(time.time() - start_time, 2))

if len(pins) > 0:
    print "WARNING :: {} Left over Nodes: {}".format(len(pins), pins)
if len(missing) > 0:
    print "WARNING :: {} Missing Nodes: {}".format(len(missing), missing)
