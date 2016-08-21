#!/bin/sh
# mysqldump of all of the db's running, including schema, compresses and dates them
# prunes older archives
# requires binary logging to be enabled i.e.
# [mysqld]
# log-bin=mysql-bin
# call this in cron i.e.
# * 22 * * * /usr/local/bin/mysqldump-foreman.sh >/dev/null 2>&1

dump_date=$(/bin/date +%Y%m%d%H%M)
dump_dest='/srv/backup/foreman/'
mysqldump=`which mysqldump`
mysqldump_opts='--all-databases --opt --single-transaction --master-data'
backuplog='/var/log/mysqldump-foreman.log'
expired_archives=`find $dump_dest -type f -ctime +120 -exec ls {} \;`
rmexpired_archives=`find $dump_dest -type f -ctime +120 -exec rm -rf {} \;`

if ! [ -d $dump_dest ]; then
     mkdir $dump_dest
fi

if [ -d $dump_dest ]; then
   echo "(`date`) mysqldump-foreman: backup starting: mysqldump-foreman-${dump_date}.gz" >> $backuplog 
   $mysqldump $mysqldump_opts | /usr/bin/gzip - > $dump_dest/mysqldump-foreman-${dump_date}.gz;
   echo "(`date`) mysqldump-foreman: backup complete: mysqldump-foreman-${dump_date}.gz" >> $backuplog 
fi

# remove archives older than 120 days
echo "(`date`) mysqldump-foreman: removing archives older than 120 days:" >> $backuplog
for x in $expired_archives; 
   do printf "(`date`) mysqldump-foreman: [removing] $x\n" >> $backuplog; 
   $rmexpired_archives;	
done
