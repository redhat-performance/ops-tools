#!/usr/bin/env python
#-*- coding: iso-8859-15 -*-
# simple, dirty tool to interactively copy ssh keys to hosts

import os
import sys

# print hosts menu
menu = """
---------------------------
|   SSH Key Copier 5000   |
---------------------------

"""
print "%s" % (menu)

# prompt for target hosts
print "Enter Target Hosts"
ssh_hosts = ""
stopword = ""
while True:
    line = str(raw_input())
    if line.strip() == stopword:
		break
    ssh_hosts += "%s\n" % line

os.system('clear')

# prompt for keys
print "Enter SSH Keys"
ssh_keys = ""
stopword = ""
while True:
    line = str(raw_input())
    if line.strip() == stopword:
		break
    ssh_keys += "%s\n" % line

os.system('clear')

# iterate through keys, hosts and copy
def CopyKeys():
	for key in ssh_keys.splitlines():
		for host in ssh_hosts.splitlines():
			copycommand = "ssh -n root@%s 'echo %s >> ~/.ssh/authorized_keys'" % (host,key)
			print "Copying SSH Keys to %s" % (host)
			os.system(copycommand)
CopyKeys()
