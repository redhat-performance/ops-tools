#!/bin/sh
# simple one-liner to check connectivity of overcloud
# assumes first host is the UC node within an environment.

source /home/stack/stackrc ; for h in $(/usr/bin/nova list | grep overc | awk '{ print $12 }' | awk -F= '{ print $2 }') ; do ping -c 3 $h ; done
