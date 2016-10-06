#!/bin/sh
# simple tool to scrape a Nagios interface and reconstruct a read-only page
# useful for displaying an internal Nagios interface externally/read only
# this is a local version of nagios-generate-dashboard.sh, meant for hosting on
# the same host where Nagios runs.
# This assumes an HTTPS internal Nagios host

tempdir=$(mktemp -d /tmp/nagiosXXXXXX)
miscfiles=/usr/share/nagios/html
nagioshost=localhost
nagiospathurl='/nagios/cgi-bin/status.cgi?hosts=all&limit=0'
nagiospass="YOURPASSHERE"
localpath=/var/www/html/health/

generate_nagios() {
	cd $tempdir
	# pull down status page
	wget -q --no-check-certificate --user=nagiosadmin --password=$nagiospass -O - \
		'https://'$nagioshost''$nagiospathurl'' > nagios.html
        # strip out only things necessary for viewing status
        sed -e "s,\(.*\)href='/nagios/\(.*\),\1href='./\2," -e \
		's,\(.*\)href="/nagios/\(.*\),\1href="./\2,' -e \
		"s,IMG SRC='/nagios/,IMG SRC='./,g" < nagios.html > index.html
	# copy modified index to local host
        cp index.html $localpath 1>/dev/null 2>&1
}

cleanup_files() {
	# cleanup
	cd /root
	rm -rf $tempdir
        # images and stylesheets are stock nagios, copy them over.
        rsync -aH $miscfiles/images $localpath
        rsync -aH $miscfiles/stylesheets $localpath
}

if generate_nagios ; then
	cleanup_files
else
	echo "Nagios Template Failed, Exiting."
	exit 1
fi
