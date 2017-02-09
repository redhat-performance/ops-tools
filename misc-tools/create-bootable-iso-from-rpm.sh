#!/bin/sh
# this is used for building new PXE capable ISO images from RHEVH
# but could be used or modified to be used to create bootable ISO's from a remote source.
# first checks if there are any changes to your local copy (in this case an rpm).
# in this particular example we're syncing the latest RHEV-H RPM from a builder, exploding
# it and calling livecd-iso-to-pxeboot to create bootable media then copying the PXE substructure
# into Foreman for provisioning.  Afterwards it will remount the new ISO and update fstab for you.
# https://access.redhat.com/site/documentation/en-US/Red_Hat_Enterprise_Virtualization_for_Servers/2.1/html/5.4-2.1_Hypervisor_Deployment_Guide/sect-Deployment_Guide-Preparing_Red_Hat_Enterprise_Virtualization_Hypervisor_installation_media-Deploying_RHEV_Hypervisors_with_PXE_and_tftp.html
# requires livecd-tools package
# run from cron via: * 14 * * * /root/create-bootable-iso-from-rpm.sh > /var/log/iso-create-from-rpm.log 2>&1

sourcebuild='your.remote.rsync.host'
downloadcache=/srv/downloads/README-RHEVH

builddate()
{
  /bin/date +%Y%m%d%H%M
}

localpxedir='/srv/distro/RHEV-H/'
localbuilddir='/srv/distro/RHEV-H-rpm'

rpmfile()
{
   rsync -l rsync://$sourcebuild/rhev-hypervisor*.rpm | awk '{print $5}'
}

newbuild()
{
   rsync -dnv  --include 'rhev-hypervisor*rpm' --exclude '?**?' --exclude '??' rsync://$sourcebuild/ $localbuilddir/ | egrep 'rhev-hypervisor.*rpm' | wc -l
}

getnewbuild()
{
   rsync -d   --delete --include 'rhev-hypervisor*rpm' --exclude '?**?' --exclude '??' rsync://$sourcebuild/ $localbuilddir/
}

precheck_against_current()
{
   touch $downloadcache
   if [ "$(rpmfile)" == "`cat $downloadcache`" ]; then
     return 0
   else 
     return 1
   fi
}

update_fstab()
{  # obtain name of new ISO image to update fstab
   echo "updating fstab with new ISO..."
   sed -i "s/rhevh.*/$(newiso) \/srv\/distro\/RHEV-H iso9660 loop,ro,auto 0 0/g" /etc/fstab 
}

build_rhevh()
{  # function to call livecd-tools and build PXE substructure
   cd $localbuilddir
   echo "extracting ISO image from RPM build file..."
   rpmfile > $downloadcache
   rpm2cpio $localbuilddir/$(rpmfile) | cpio -idmv
   echo "creating PXE substructure from extracted ISO image..."
   livecd-iso-to-pxeboot ./usr/share/rhev-hypervisor/rhevh-*.iso
   echo "copying PXE files into Foreman..."
   cp $localbuilddir/tftpboot/initrd0.img /var/lib/tftpboot/boot/RHEV-H-Latest-initrd.img
   echo "remounting new ISO image for updated installation media..."
   umount /srv/distro/RHEV-H
   rm /srv/downloads/rhevh-*.iso
   cp $localbuilddir/usr/share/rhev-hypervisor/rhevh-*.iso /srv/downloads/
   mount -t iso9660 -o loop /srv/downloads/rhevh-*.iso /srv/distro/RHEV-H 
   cp $localbuilddir/tftpboot/vmlinuz0 /var/lib/tftpboot/boot/RHEV-H-Latest-vmlinuz
   update_fstab
   echo "cleaning up.."
   rm -rf $localbuilddir/{tftpboot,usr}
   echo "done!"
}

newiso()
{
  mount | grep rhev | awk 'BEGIN { FS = "/" } ; { print $4 }' | awk '{print $1}'
}

case $(newbuild) in
'0')
   echo "no new builds available on $(builddate), quitting!"
   ;;
'1')
   if $(precheck_against_current) ; then
     echo Nothing to do.  We have the latest download.
     exit 0
   fi
   echo "fetching a new build based on $(builddate) RPM source"
   echo "this might take a while..."
   getnewbuild
   build_rhevh
   ;;
*)
   echo What am I doing here .. I should be..... aborting.
   exit 1
   ;;
esac
