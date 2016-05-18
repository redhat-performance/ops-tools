#!/bin/bash
# backup libvirt data to a remote NFS share once a day at 14:00
# rsync will let us incrementally copy changed blocks
# we'll run this daily via:
# 00 14 * * * /root/libvirt-backup-nfs.sh >/dev/null 2>&1
# we will log all data and timestamps

local_backupdir='/var/lib/libvirt'
remote_backupdir='/srv/remote_backups/'
remote_backupdir_fs=`stat -f -L -c %T $remote_backupdir`
rsync_installed=`rpm -qa | grep rsync |wc -l`
logfile='/var/log/libvirt-backup.log'

# log all activity
start_logging() {
    exec > >(gawk -v pid=$$ '{ print strftime("%F-%T"),pid,$0; fflush(); }' | tee -a $logfile)
    [ ! -z "$DEBUG" ] && exec 2>&1 || exec 2> >(gawk -v pid=$$ '{ print strftime("%F-%T"),pid,$0; fflush(); }' >>$logfile)
    echo "=== Log beginning for $$ at $(date +%F-%T) ==="
}

# check that rsync is installed
check_rsync() {

	echo "checking for rsync.."
	if [[ $rsync_installed = '0' ]]
	then
		echo "rsync not present, installing.."
		yum install rsync -y >/dev/null 2>&1
	else
                echo "[OK] rsync installed"
        fi
}

# check if remote backup is mounted
check_backupdir_mount() {
	echo "checking if remote NFS available.."
	if [[ $remote_backupdir_fs = 'nfs' ]]
	then	
		echo "[OK] NFS storage mounted"
	else
		echo "[ERROR] NFS storage unavailable, quitting"
                exit 1	
	fi
}

# backup data via rsync
backup_libvirt_data() {
	echo "backing up libvirt data via rsync.."
        rsync -av $local_backupdir $remote_backupdir >/dev/null 2>&1
        echo "[COMPLETE]"
}

start_logging
check_rsync
check_backupdir_mount
backup_libvirt_data
