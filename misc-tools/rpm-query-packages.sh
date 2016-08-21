#!/bin/sh
# compares package differences between two hosts:
# usage:
#
#    [kambiz@vorlon (home)]$ ssh  -q root@graph01.oslab.example.com rpm -qa > /tmp/graph01-rpm-qa
#    [kambiz@vorlon (home)]$ ssh  -q root@graph02.oslab.example.com rpm -qa > /tmp/graph02-rpm-qa
#     
#    [kambiz@vorlon (home)]$ cd /tmp
#     
#    [kambiz@vorlon (home)]$ ~/git/oslab-tools/bin/compare-rpm-qa.sh graph01-rpm-qa graph02-rpm-qa
#    kernel-core appears more than once in graph01-rpm-qa
#    kernel-core appears more than once in graph01-rpm-qa
#    kernel-core appears more than once in graph01-rpm-qa
#    kernel-modules appears more than once in graph01-rpm-qa
#    kernel-modules appears more than once in graph01-rpm-qa
#    kernel-modules appears more than once in graph01-rpm-qa
#    kernel-core appears more than once in graph02-rpm-qa
#    kernel-core appears more than once in graph02-rpm-qa
#    kernel-core appears more than once in graph02-rpm-qa
#    kernel-modules appears more than once in graph02-rpm-qa
#    kernel-modules appears more than once in graph02-rpm-qa
#    kernel-modules appears more than once in graph02-rpm-qa
#    nspr-4.10.8-1.fc22.x86_64 nspr-4.10.10-1.fc22.x86_64
#    rpm-4.12.0.1-13.fc22.x86_64 rpm-4.12.0.1-12.fc22.x86_64
#    rpm-build-libs-4.12.0.1-13.fc22.x86_64 rpm-build-libs-4.12.0.1-12.fc22.x86_64
#    rpm-libs-4.12.0.1-13.fc22.x86_64 rpm-libs-4.12.0.1-12.fc22.x86_64
#    rpm-plugin-selinux-4.12.0.1-13.fc22.x86_64 rpm-plugin-selinux-4.12.0.1-12.fc22.x86_64
#    rpm-plugin-systemd-inhibit-4.12.0.1-13.fc22.x86_64 rpm-plugin-systemd-inhibit-4.12.0.1-12.fc22.x86_64
#    rpm-python-4.12.0.1-13.fc22.x86_64 rpm-python-4.12.0.1-12.fc22.x86_64
#    sqlite-3.8.10.2-1.fc22.x86_64 sqlite-3.9.0-1.fc22.x86_64
#     
#     
#    [kambiz@vorlon (home)]$ wc -l only-graph01-rpm-qa
#    32 only-graph01-rpm-qa
#     
#    [kambiz@vorlon (home)]$ wc -l only-graph02-rpm-qa
#    94 only-graph02-rpm-qa

file1=$1
file2=$2
onlyfile1=only-$file1
onlyfile2=only-$file2

rm -f $onlyfile1 $onlyfile2

tmpfile1=$(mktemp /tmp/rpmqa1-XXXXXX)
sort < $file1 > $tmpfile1

tmpfile2=$(mktemp /tmp/rpmqa2-XXXXXX)
sort < $file2 > $tmpfile2

# make sure things are sane ...

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile1) ; do 
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -gt 1 ]; then 
      echo $pkg appears more than once in $file1
    fi
  fi
done

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile2) ; do 
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -gt 1 ]; then 
      echo $pkg appears more than once in $file2
    fi
  fi
done

# now look for things in file1 that are not in file2

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile1) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -ne 1 ]; then 
      echo $pkg >> $onlyfile1
    fi
  fi
done

# now look for things in file2 that are not in file1

for pkg in $(sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' < $tmpfile2) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -ne 1 ]; then 
      echo $pkg >> $onlyfile2
    fi
  fi
done

# finally compare the ones that appear in both
for pkg in $(cat $tmpfile1 $tmpfile2 | sed 's/\(.*\)-[^\-][^\-]*-[^\-][^\-]*.*/\1/g' | sort -u) ; do
  if [ "$pkg" != "kernel" ]; then
    if [ $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1) -eq 1 -a $(egrep -c "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2) -eq 1 ]; then 
      pkg1=$(egrep "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile1)
      pkg2=$(egrep "^$(echo ${pkg} | sed 's/\+/\\\+/g')-[0-9]" $tmpfile2)
      if [ "$pkg1" != "$pkg2" ]; then
        echo $pkg1 $pkg2
      fi
    fi
  fi
done

rm -f $tmpfile1 $tmpfile2
