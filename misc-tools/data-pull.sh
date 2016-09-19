#!/bin/bash
# tool to pull down all remote data via remote http
# and create a local yum repo
# similiar to rpm-pull but pulls all data/dir format
# requires createrepo and wget, will install if needed
#
# USAGE :: ./data-pull.sh $REMOTEDATA $LOCALDATA

remote_data=$1
local_data=$2

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: ./data-pull.sh \$REMOTEDATA \$LOCALDATA"
        exit 1
fi

# check if local_data dir exists
if [[ ! -d $2 ]]; then
        echo "local directory $2 does not exist, creating!"
        mkdir -p $2
fi

# if local_data is unable to be created, quit
if [[ ! -d $2 ]]; then
        echo "unable to create $2, check permissions."
        exit 1
fi

createrepo_installed=`rpm -qa | grep createrepo |wc -l`
wget_installed=`rpm -qa | grep wget|wc -l`

# check that we have the right tools installed first.
check_repoutils() {

	echo "checking package dependencies.."
	if [[ $createrepo_installed = '0' ]]
	then
		echo "createrepo not installed.. installing"
		yum install createrepo -y >/dev/null 2>&1
	
	elif [[ $wget_installed = '0' ]]
        then
		echo "wget not installed.. installing"
		yum install wget -y >/dev/null 2>&1
	else
                echo "[OK]"
        fi
}

# sync the remote data
pull_data() {
	echo "syncing data from $remote_data"
	echo "..this may take a while"
        cd $local_data ; wget -N -r -nH --cut-dirs=2 --no-parent \
		--reject="index.html*" $remote_data >/dev/null 2>&1
	echo "data pull complete!"
	  if [[ -d $local_data/repodata ]]
          then
        	echo "removing old repodata"
                rm -rf $local_data/repodata
		echo "creating new repo structure in $local_data"
	  else
	        echo "creating new repo structure in $local_data"
	  fi
	cd $local_data ; createrepo . >/dev/null 2>&1
	echo "Job's done!"
	echo "                  "
	filecount=`find $local_data -type f |wc -l`
	echo "Total Files: $filecount"
	echo "FROM: $remote_data"
	echo "SYNC: $local_data"
	echo "                  "
}

check_repoutils
pull_data
