#!/usr/bin/env python
# simple encryption/archival tool
# tar and gpg encrypt a file or directory and copy it locally
# the local destination could be a remote share or rsync'd location

import argparse
import sys
import os
import datetime

# define optional verbose argument
parser=argparse.ArgumentParser()
parser.add_argument('--verbose', help="increase verbosity output")

# force the main arguments to be required (and listed in help as such)
requiredArgs=parser.add_argument_group('Required Arguments')
requiredArgs.add_argument('--recipient', required=True, help="GPG recipient")
requiredArgs.add_argument('--data', required=True, help="data to backup")
requiredArgs.add_argument('--backup', required=True, help="backup destination")
requiredArgs.add_argument('--backupname', required=True, help="backup file name")

# print help if no arguments are provided
if len(sys.argv)==1:
    parser.print_help()
    print """
Example Usage:
./backup-file.py --recipient 0123 --data somefile --backup /backups \
--backupname backupfile --verbose on
"""
    sys.exit(1)

# use the parse_args method for arguments
args=parser.parse_args()

# error on bad input
if not args:
    print "ERROR, check syntax and arguments"
    sys.exit(1)

# make a variable for timestamp, e.g. 2015471826
timestamp = '-' + datetime.datetime.now().strftime('%Y%m%d%H%M')

# print options if verbose is turned on
if args.verbose:
    print "verbosity turned on"
    if args.recipient:
        print "Recipient: " + args.recipient
    if args.data:
        print "Data: " + args.data 
    if args.backup:
        print "Backup To: " + args.backup
    if args.backupname:
        print "Backup Name: " + args.backupname + timestamp

# check if backup file exists
if os.path.exists(os.path.join (args.backup, args.backupname + timestamp + '.tar.gz.gpg')):
    print "ERROR, Backup Name: " + args.backupname + timestamp + " Exists!",
    sys.exit(1)

# check if file open would succeed and you are using a sane location
try:
       open(args.backup + '/' + args.backupname + timestamp + '.tar.gz.gpg', 'w')
except IOError:
       print "Unable to open the backup destination."

# define our tar and encrypt commands
from subprocess import Popen, PIPE
gpg_output = open(args.backup + '/' + args.backupname + timestamp + '.tar.gz.gpg', 'w')
tar_command = Popen(['tar', '-cvz', args.data], stdout=PIPE)
gpg_command = Popen(['gpg', '-e', '-r', args.recipient], stdin=tar_command.stdout, \
        stdout=gpg_output)
out, err = gpg_command.communicate()
