#!/usr/bin/env python

# Simple python cli tool for copying public ssh keys to authorized_keys file
# on remote host via the python paramiko library.

from paramiko import SSHClient, AutoAddPolicy
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Copy public ssh key to authorized_keys on a remote host."
    )
    parser.add_argument(
        "--host", dest="host", type=str, default=None, help="Remote host"
    )
    parser.add_argument(
        "--user", dest="user", type=str, default=None, help="Remote user"
    )
    parser.add_argument(
        "--passwd", dest="passwd", type=str, default=None, help="Remote pass"
    )
    parser.add_argument(
        "--ssh-key", dest="ssh_key", type=str, default=None, help="Public SSH Key"
    )
    _args = parser.parse_args()

    ssh = SSHClient()
    ssh.set_missing_host_key_policy(AutoAddPolicy())
    ssh.load_system_host_keys()

    ssh.connect(
        _args.host,
        username=_args.user,
        password=_args.passwd,
        look_for_keys=False,
        allow_agent=False,
    )
    transport = ssh.get_transport()
    channel = transport.open_session()
    channel.setblocking(1)

    with open(_args.ssh_key, "r") as _file:
        key = _file.readline().strip()

    command = 'echo "%s" >> ~/.ssh/authorized_keys' % key
    stdin, stdout, stderr = ssh.exec_command(command)

    if stderr.readlines():
        print("There was something wrong with your request")
        for line in stderr.readlines():
            print(line)
    else:
        print("Your key was copied succesfully")
