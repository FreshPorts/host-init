#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh


# clear this, in case we messed it up and are running this script again.
for set in $caching_sets
do
   # it has to be unjailed in order for the subsequent operations to succeed. Otherwise: dataset is used in a non-global
   zfs set jailed=off      ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}
done
   
# unjail it
zfs set jailed=off ${datazpool}/freshports/jailed/$WEB_JAIL/cache
   
for set in $caching_sets
do
   zfs set canmount=on     ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}
   zfs inherit jailed      ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}
   zfs inherit mountpoint  ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}
done

# jail it
# let's set only the top level filesystem jailed
# the children should follow inheritance.
zfs set jailed=on ${datazpool}/freshports/jailed/$WEB_JAIL/cache

jexec $WEB_JAIL mkdir -p /var/db/freshports/cache

service jail restart $WEB_JAIL
zfs jail $WEB_JAIL ${datazpool}/freshports/jailed/$WEB_JAIL/cache

jexec $WEB_JAIL zfs set mountpoint=/var/db/freshports/cache ${datazpool}/freshports/jailed/$WEB_JAIL/cache

for set in $caching_sets
do
   # allow freshports to rollback
   jexec $WEB_JAIL zfs allow freshports rollback ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}

#  quite sure thsi is not required because it gets mounted
#   jexec $WEB_JAIL zfs mount                     ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}
   jexec $WEB_JAIL chown www:freshports /var/db/freshports/cache/${set}
   jexec $WEB_JAIL chmod g+w            /var/db/freshports/cache/${set}


   # this snapshot must be last or you'll undo the chown above when you rollback
   jexec $WEB_JAIL zfs snapshot                  ${datazpool}/freshports/jailed/$WEB_JAIL/cache/${set}@empty
done


# Enable the search log. This has always been a thing, and never really used.
jexec $WEB_JAIL touch                /var/db/freshports/cache/searchlog.txt
jexec $WEB_JAIL chown www:freshports /var/db/freshports/cache/searchlog.txt
jexec $WEB_JAIL chmod 0644           /var/db/freshports/cache/searchlog.txt

# I am not sure why this needs to be done, but when configuring x8dtu, it was required.
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/cache/html 
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/cache/spooling
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/freshports/message-queues
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/freshports/repos
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/ingress/message-queues
#zfs inherit mountpoint ${datazpool}/freshports/$INGRESS_JAIL/ingress/repos
#
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/cache/html 
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/cache/spooling
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/freshports/message-queues
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/freshports/repos
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/ingress/message-queues
#zfs mount ${datazpool}/freshports/$INGRESS_JAIL/ingress/repos

jexec $WEB_JAIL mkdir -p /var/db/freshports/cache/html
