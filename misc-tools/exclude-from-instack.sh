#!/usr/bin/bash
# wrapper for setting QUADS host parameter that enables
# or disables participation in an overcloud.

function usage() {
    echo "USAGE:   `dirname $0`/`basename $0` -e <true|false> -h \$HOSTNAME -c <cloudname> -u foremanuser -p foremanpassword"
    echo "         `dirname $0`/`basename $0` -l <cloudname> -u foremanuser -p foremanpassword"
    echo "         `dirname $0`/`basename $0` --excluded-hosts <cloudname> -u foremanuser -p foremanpassword"
    echo ""
    echo "EXAMPLE: `dirname $0`/`basename $0` -e true -h c08-h01-r930.rdu.openstack.engineering.example.com -c cloud12 -u cloud12 -p 123456"
    echo "EXAMPLE: `dirname $0`/`basename $0` -l cloud12 -u cloud12 -p 123456"
    echo ""
}

function list_cloud_includes() {
	target=$1
	user=$2
	password=$3
	selection=$4

	echo hammer -u $user -p $password host list --search params.nullos=$selection | grep example.com | awk '{ print $3 }'
	hammer -u $user -p $password host list --search params.nullos=$selection | grep example.com | awk '{ print $3 }'
}

function set_bootstate() {
	target=$1
	nullos=$2
	user=$3
	password=$4
	echo hammer host set-parameter --host $target --name nullos --value $nullos
	hammer host set-parameter --host $target --name nullos --value $nullos

}


function clean_interfaces() {
	tmpfile=$(mktemp /tmp/foremanXXXXXX)
	problemhost=$1
	skip_id=$(hammer host info --name $problemhost | grep -B 3 "nterface (primary, provision" | grep Id: | awk '{ print $NF }')
	hammer host info --name $problemhost > $tmpfile
	for interface in $(grep Id $tmpfile  | grep ')' | grep -v $skip_id | awk '{ print $NF }') ; do \
	hammer host interface delete --host $problemhost --id $interface \
	;done
	rm -f $tmpfile

}

function check_access() {
	hostname=$1
	user=$2
	pass=$3

	result=$(hammer -u $user -p $pass host list  | grep $hostname)
	if [ -z "$result" ]; then
		echo "You do not appear to have access to $hostname"
		exit 1
	fi
}

	
args=`getopt -o l:u:p:e:c:h: -l excluded-hosts:,list:,user:,password:,exclude:,cloud:,host:,help -- "$@"`

if [ $? != 0 ] ; then usage ; echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$args"
while true ; do
        case "$1" in
                -u|--user)
                        user=$2 ; shift 2;
                        if [ "$(echo $user | cut -c 1)" = "-" -o -z "$user" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                 -p|--password)
                        password=$2 ; shift 2;
                        if [ "$(echo $password | cut -c 1)" = "-" -o -z "$password" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                 -e|--exclude)
                        exclude=$2 ; shift 2;
                        if [ "$(echo $exclude | cut -c 1)" = "-" -o -z "$exclude" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                 -c|--cloud)
                        cloudname=$2 ; shift 2;
                        if [ "$(echo $cloudname | cut -c 1)" = "-" -o -z "$cloudname" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                -h|--host)
                        host_name=$2 ; shift 2;
                        if [ "$(echo $host_name | cut -c 1)" = "-" -o -z "$host_name" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                 -l|--list)
			list_include=true
                        list_cloud=$2 ; shift 2;
                        if [ "$(echo $list_cloud | cut -c 1)" = "-" -o -z "$list_cloud" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                  --excluded-hosts)
			list_include=false
                        list_cloud=$2 ; shift 2;
                        if [ "$(echo $list_cloud | cut -c 1)" = "-" -o -z "$list_cloud" ]; then
                            usage ; echo "Terminating..." >&2
                            exit 1
                        fi
                        ;;
                 --help)
                        usage ; echo "Terminating..." >&2
                        exit 1
                        ;;
                --)
                        shift ; break ;
                        ;;
        esac
done

foreman_hostname=$host_name

if [ -z "$cloudname" -a -z "$list_cloud" ]; then
    usage ; echo "Terminating..." >&2
    exit 1
fi

if [ -z "$user" -o -z "$password" ]; then
    usage ; echo "Terminating..." >&2
    exit 1
fi

if [ "$list_cloud" ]; then
    list_cloud_includes $list_cloud $user $password $list_include
    exit 0
fi

case $exclude in
'true')
	nullos_variable=false
	;;
'false')
	nullos_variable=true
	;;
*)
    usage ; echo "Terminating..." >&2
    exit 1
    ;;
esac

if [ -z "$foreman_hostname" ]; then
    usage ; echo "Terminating..." >&2
    exit 1
fi

check_access $foreman_hostname $user $password

# first clean any extraneous interfaces that have been collected
clean_interfaces $foreman_hostname
set_bootstate $foreman_hostname $nullos_variable $user $password
