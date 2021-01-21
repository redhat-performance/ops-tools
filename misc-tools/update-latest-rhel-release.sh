#!/bin/bash
# update to latest RHEL U-release.
# don't do it if you already have it.
# ./update-latest-rhel-release.sh 8.3
#
el_target=$1

# print usage if not specified
if [[ $# -eq 0 ]]; then
    echo "USAGE:   ./update-latest-rhel-release \$OSVERSION"
    echo "EXAMPLE: ./update-latest-rhel-release 8.3"
    echo "                                         "
    exit 1
fi

# check to ensure user is root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

el_current=`cat /etc/redhat-release | awk '{print $6}'`

# are you on the latest?
if [[ $el_target = $el_current ]]; then
    echo "Current RHEL version $el_current matches requested version."
    exit 1
        else
        :
fi

# backup and modify yum repository
change_el_repo() {
    tar_short=`echo ${el_target//.}`
    cur_short=`echo ${el_current//.}`
    curdate=`/bin/date +%Y%m%d%H%M`
    for repo in $(cd /etc/yum.repos.d ; ls RHEL*-*.repo);
        do cp $repo /root/$repo.$curdate;
            done
    echo "Changing repository from $el_current to $el_target"
    sed -i "s/$el_current.0/$el_target.0/" /etc/yum.repos.d/RHEL*-*.repo
    sed -i "s/rhel$cur_short/rhel$tar_short/I" /etc/yum.repos.d/RHEL*-*.repo
    echo "Cleaning dnf repo cache.."
    dnf clean all >/dev/null 2>&1
    echo "                         "
    echo "-------------------------"
    echo "Run dnf update to upgrade to RHEL $el_target"
    echo "                         "
}
change_el_repo
