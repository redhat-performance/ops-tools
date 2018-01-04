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
print "INFO :: Opening {} for node id to node ipmi definition".format(pin_yaml)
print "----------------------------------------------"

# Open file to pin nodes
with open(pin_yaml, "r") as stream:
    pins = yaml.load(stream)

# Establish Ironic API Connection
ironic = client.get_client(
        1, os_username=os.environ['OS_USERNAME'], os_password=os.environ['OS_PASSWORD'],
        os_auth_url=os.environ['OS_AUTH_URL'], os_project_name=os.environ['OS_PROJECT_NAME'])

# Get Ironic Nodes
nodes = ironic.node.list()

# Pin each Node if found in loaded pin.yaml:
for node in nodes:
    ipmi_addr = ironic.node.get(node.uuid).to_dict()['driver_info']['ipmi_address']
    print "INFO :: UUID: {}, IPMI Address: {}".format(node.uuid, ipmi_addr)
    if ipmi_addr in pins:
        print "INFO :: Found {} in {}, setting to: {}".format(ipmi_addr, pin_yaml, pins[ipmi_addr])
        capablities_value = "node:{},cpu_vt:true,cpu_hugepages:true,boot_option:local," \
            "cpu_txt:true,cpu_aes:true,cpu_hugepages_1g:true,boot_mode:bios".format(pins[ipmi_addr])
        patch = [
            {
                "op": "replace",
                "path": "/properties/capabilities",
                "value": capablities_value,
            }
        ]
        ironic.node.update(node.uuid, patch=patch)
        del pins[ipmi_addr]
    else:
        print "WARNING :: Could not find: {} in {}".format(ipmi_addr, pin_yaml)

print "-------------------------------------------"
print "INFO :: Took {} to pin nodes.".format(round(time.time() - start_time, 2))

if len(pins) > 0:
    print "WARNING :: Left over Nodes: {}".format(pins)
