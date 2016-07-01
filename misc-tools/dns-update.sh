#!/bin/sh
# script to call nsupdate to add or delete DNS entries
# supports A records, PTR and CNAME
# does not need a named reload
# it would be foolish to buy an appliance to manage this.

nsupdate=`which nsupdate`

########## FUNCTIONS ##########
dns_add_forward()
{  # use nsupdate to make forward dns entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update add $fqdnadd 300 IN A $ipaddr
   show
   send
   quit
END_OF_SESSION
}  

dns_add_cname()
{  # use nsupdate to make forward dns entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update add $fqdnadd 300 IN CNAME $ipaddr
   show
   send
   quit
END_OF_SESSION
}  

dns_add_reverse()
{   # use nsupdate to make reverse entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $reversezone
   update add $ipaddrreverse$arpa 300 PTR $fqdnadd
   show
   send
   quit
END_OF_SESSION
}

# delete forward dns function
dns_delete_forward()
{  # use nsupdate to delete existing entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update delete $fqdndelete A
   show
   send
   quit
END_OF_SESSION
}

dns_delete_cname()
{  # use nsupdate to delete existing entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $forwardzone
   update delete $fqdndelete CNAME
   show
   send
   quit
END_OF_SESSION
}

# delete reverse dns function
dns_delete_reverse()
{   # use nsupdate to delete reverse entry
   $nsupdate <<END_OF_SESSION
   server localhost
   zone $reversezone
   update delete $ipaddrreverse$arpa PTR
   show
   send
   quit
END_OF_SESSION
}

# reverse IP address function
reverse_ip() 
{   # take the result of $ipaddr and reverse it for in.arpa
    echo "$1" | awk 'BEGIN{FS=".";ORS="."} {for (i = NF; i > 0; i--){print $i}}'
}

########## END FUNCTIONS ##########

# sanity check to ensure user is root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# present action menu
cat <<Endofmessage

=========== DNS Updater 5000 ===========
Enter the appropriate action
----------------------------
1) Add New DNS Entry
2) Delete Existing DNS Entry
----------------------------
** Enter 1 or 2 **
========================================

Endofmessage

action=$(head -n1)

########## ADD NEW DNS ENTRY SECTION ##########

if [ $action = "1" ]; then
# present sub-action menu
cat <<Endofmessage

=========== A record or CNAME ==========
Enter the appropriate action
----------------------------
1) Add New A record
2) Add New CNAME record
----------------------------
** Enter 1 or 2 **
========================================

Endofmessage

subaction=$(head -n1)

cat <<Endofmessage
----------------------------------------
Enter shortname to add/update e.g. host01
----------------------------------------
Endofmessage

fqdnadd=$(head -n1)

if [ $subaction = "1" ]; then
cat <<Endofmessage
----------------------------------------
Enter IP address for $fqdnadd
----------------------------------------
Endofmessage

ipaddr=$(head -n1)
else
cat <<Endofmessage
----------------------------------------
Enter full CNAME for $fqdnadd e.g. hobo.com
----------------------------------------
Endofmessage

ipaddr=$(head -n1)
fi

cat <<Endofmessage
----------------------------------------
Enter zone name.. e.g. scale.openstack.example.com 
or oslab.openstack.example.com
----------------------------------------
Endofmessage

forwardzone=$(head -n1).
fqdnadd=$fqdnadd.$forwardzone

if [ $subaction = "1" ]; then
ipaddrreverse=$(reverse_ip $ipaddr)
arpa='in-addr.arpa.'
reversezone=$(reverse_ip $ipaddr | cut -d "." -f2-4).$arpa
cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to add the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdnadd 300 A $ipaddr
- - - - - - - - - - - - - - - - - - - - - 
(reverse zone: $reversezone)
$ipaddrreverse$arpa 300 PTR $fqdnadd

+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage
else
cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to add the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdnadd 300 CNAME $ipaddr
+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage

fi

confirm=$(head -n1)

# call functions 'dns_add_forward' and 'dns_add_reverse'
case $confirm in
'y'|'Y')
   if [ $subaction = "1" ]; then
     dns_add_forward
     dns_add_reverse
   else
     dns_add_cname
   fi
;;
esac

# if input isn't yes quit after taunting user.
case $confirm in
'n')
   echo "fine, why don't you go cry about it some more on your blog!"
   exit 1
;;
'N')
   echo "How does it feel to live a life of dissapointment?"
   exit 1
;;
esac
fi

########## DELETE DNS ENTRY SECTION ##########

if [ $action = "2" ];
   then
cat <<Endofmessage
----------------------------------------
Enter short hostname to DELETE .. i.e. host01
----------------------------------------
Endofmessage

fqdndelete=$(head -n1)

# present action menu
cat <<Endofmessage

=========== DNS Updater 5000 ===========
Is this record a CNAME?
----------------------------
1) yes
2) no
----------------------------
** Enter 1 or 2 **
========================================

Endofmessage

subaction=$(head -n1)

if [ "$subaction" = "2" ]; then
cat <<Endofmessage
----------------------------------------
Enter IP address to DELETE for $fqdndelete
----------------------------------------
Endofmessage

ipaddr=$(head -n1)

fi

cat <<Endofmessage
----------------------------------------
Enter zone name to DELETE entry from..
e.g. scale.openstack.example.com 
or oslab.openstack.example.com
----------------------------------------
Endofmessage

forwardzone=$(head -n1).

if [ "$subaction" = "2" ]; then
ipaddrreverse=$(reverse_ip $ipaddr)
arpa='in-addr.arpa.'
reversezone=$(reverse_ip $ipaddr | cut -d "." -f2-4).$arpa
fi

fqdndelete=$fqdndelete.$forwardzone

if [ "$subaction" = "2" ]; then

cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to DELETE the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdndelete 300 A $ipaddr
- - - - - - - - - - - - - - - - - - - - -
(reverse zone: $reversezone$arpa)
$ipaddrreverse$arpa 300 PTR $fqdndelete

+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage

else
cat <<Endofmessage

+ + + + + + + + + + + + + + + + + + + + +
You're about to DELETE the following entry..
+ + + + + + + + + + + + + + + + + + + + +

(forward zone: $forwardzone)
$fqdndelete 300 CNAME
+ + + + + + + + + + + + + + + + + + + + +
Are you sure?  (Y/N)
Endofmessage

fi

confirmdelete=$(head -n1)

# call functions 'dns_delete_forward' and 'dns_delete_reverse'
case $confirmdelete in
'y'|'Y')
   if [ "$subaction" = "2" ]; then
     dns_delete_forward
     dns_delete_reverse
   else
     dns_delete_cname
   fi
;;
esac

# if input isn't yes quit after a good insult.
case $confirmdelete in
'N')
   echo "Why don't you go cry about it on your blog then!"
   exit 1
;;
'n')
   echo "your insolence is unacceptable!"
   exit 1
;;
esac
fi
