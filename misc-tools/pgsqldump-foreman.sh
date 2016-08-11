#!/bin/bash
# postgresql backup of all foreman databases and schema, compresses and date them
# prunes older archives
# call this in cron i.e.
# * 22 * * * /usr/local/bin/pgsqldump-foreman.sh >/dev/null 2>&1

# common variables
dump_date=$(/bin/date +%Y%m%d%H%M)
dump_dest='/home/backups/'
pgsqldump=`which pg_dumpall`
pgsqluser_prefix='su postgres -c'
backuplog='/var/log/pgsqldump-foreman.log'
expired_archives=`find $dump_dest -type f -ctime +120 -exec ls {} \;`
rmexpired_archives=`find $dump_dest -type f -ctime +120 -exec rm -rf {} \;`

# check if dumpdir exists
if ! [ -d $dump_dest ]; then
    mkdir $dump_dest
    echo "creating backup destination"
fi

# backup databases, gzip and log
if [ -d $dump_dest ]; then
    echo "(`date`) pgsqldump-foreman: backup starting: pgsqldump-foreman-${dump_date}.gz" >> $backuplog
    $pgsqluser_prefix $pgsqldump | /usr/bin/gzip - > $dump_dest/pgsqldump-foreman-${dump_date}.gz;
    echo "(`date`) pgsqldump-foreman: backup complete: pgsqldump-foreman-${dump_date}.gz" >> $backuplog
fi

# remove archives older than 120 days
echo "(`date`) pgsqldump-foreman: removing archives older than 120 days:" >> $backuplog
for x in $expired_archives;
    do printf "(`date`) pgsqldump-foreman: [removing] $x\n" >> $backuplog;
   $rmexpired_archives;
done
