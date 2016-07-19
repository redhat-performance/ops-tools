# tool to pull down remote RPM's on RHEL, CentOS, Fedora
# and create a local yum repo
# we use this in lieu of reposync because not all remote http
# locations will properly have repo format
# requires createrepo and wget, will install if needed
#
# USAGE :: ./rpm-pull.sh $REMOTEREPO $LOCALREPO

remote_repo=$1
local_repo=$2

# print usage if not specified
if [[ $# -eq 0 ]]; then
        echo "USAGE: ./rpm-pull.sh \$REMOTEREPO \$LOCALREPO"
        exit 1
fi

# check if local_repo dir exists
if [[ ! -d $2 ]]; then
        echo "local directory $2 does not exist, creating!"
        mkdir -p $2
fi

# if local_repo is unable to be created, quit
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

pkglist=`wget -q -O - $remote_repo | grep rpm | sed 's/.*href="\(.*rpm\)">.*/\1/'`

# sync our remote repo
pull_repo() {
	echo "syncing RPM's from $remote_repo"
	echo "..this may take a while"
	for pkg in $pkglist ; do 
          # assume if we have a local file with target name
          # and its a valid RPM file, then we dont need to pull
          if [[ -f $local_repo/$pkg ]] && rpm -qp $local_repo/$pkg 1>/dev/null 2>&1 ; then
            :
          else
            wget -nc -q -O - $remote_repo/$pkg > $local_repo/$pkg 
          fi
        done 
	echo "RPM pull complete!"
	  if [[ -d $local_repo/repodata ]]
          then
        	echo "removing old repodata"
                rm -rf $local_repo/repodata
		echo "creating new repo structure in $local_repo"
	  else
	        echo "creating new repo structure in $local_repo"
	  fi
	cd $local_repo ; createrepo . >/dev/null 2>&1
	echo "Job's done!"
	echo "                  "
	rpmcount=`ls $local_repo | grep *.rpm |wc -l`
	echo "RPM Packages: $rpmcount"
	echo "FROM: $remote_repo"
	echo "SYNC: $local_repo"
	echo "                  "
}

check_repoutils
pull_repo
