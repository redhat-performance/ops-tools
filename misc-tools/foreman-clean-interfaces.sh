#/bin/bash
# remove all non-primary interfaces via Foreman CLI
# usage ./foreman-clean-interfaces.sh $hostname
# workaround for: http://projects.theforeman.org/issues/11434

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE:   ./scalelab-foreman-clean-interface.sh \$HOSTNAMEFQDN"
	echo "EXAMPLE: ./scalelab-foreman-clean-interface.sh host03-rack10.example.com"
	echo "                                      "
	exit 1
fi

#check to ensure user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

problemhost=$1
skip_id=$(hammer host info --name $problemhost | grep -B 3 "nterface (primary, provision" | grep Id: | awk '{ print $NF }')
hammer host info --name $problemhost > /tmp/$problemhost

for interface in $(grep Id /tmp/$problemhost  | grep ')' | grep -v $skip_id | awk '{ print $NF }') ; do \
hammer host interface delete --host $problemhost --id $interface \
;done
