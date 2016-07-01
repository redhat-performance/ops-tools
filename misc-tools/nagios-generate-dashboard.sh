#!/bin/sh
# simple tool to scrape a Nagios interface and reconstruct a read-only page
# useful for displaying an internal Nagios interface externally/read only

tempdir=$(mktemp -d /tmp/nagiosXXXXXX)
miscfiles=/root/nagios
nagioshost=host02.example.com
nagiospathurl='/nagios/cgi-bin/status.cgi?hosts=all'
nagiospass=YOURPASSWORD
remotehost=host01.example.com
remotepath=/usr/share/openstack-dashboard/static/dashboard/nagios/

generate_nagios() {
	cd $tempdir
	# pull down status page
	wget -q --user=nagiosadmin --password=$nagiospass -O - \
		'http://'$nagioshost''$nagiospathurl'' > nagios.html
        # strip out only things necessary for viewing status
        sed -e "s,\(.*\)href='/nagios/\(.*\),\1href='./\2," -e \
		's,\(.*\)href="/nagios/\(.*\),\1href="./\2,' -e \
		"s,IMG SRC='/nagios/,IMG SRC='./,g" < nagios.html > index.html
	# copy modified index to remotehost
	scp index.html $remotehost:$remotepath 1>/dev/null 2>&1
}

cleanup_files() {
	# cleanup
	cd /root
	rm -rf $tempdir
        # images and stylesheets are stock nagios.
	rsync -aH -e ssh $miscfiles/images $remotehost:$remotepath 1>/dev/null 2>&1
	rsync -aH -e ssh $miscfiles/stylesheets $remotehost:$remotepath 1>/dev/null 2>&1
}


if generate_nagios ; then
	cleanup_files
else
	echo "Nagios Template Failed, Exiting."
	exit 1
fi
