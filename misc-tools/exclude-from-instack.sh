#!/usr/bin/bash
# wrapper to hammer some common hammer commands
# This lets you:
# set boostate for director
# remove boostate for director
# list machines included or excluded in the instackenv.json

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

	hammer -u $user -p $password host list --search params.nullos=$selection | grep example.com | awk '{ print $3 }'
}

function set_bootstate() {
	target=$1
	nullos=$2
	user=$3
	password=$4
	echo hammer -u $user -p $password host set-parameter --host $target --name nullos --value $nullos

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
nullos_variable=$exclude

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

case $nullos_variable in
'true'|'false')
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


set_bootstate $foreman_hostname $nullos_variable $user $password
