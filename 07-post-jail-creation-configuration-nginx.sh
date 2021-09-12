#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

zfs set jailed=on ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports

jexec $WEB_JAIL zfs set mountpoint=/var/db/freshports/cache ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache

# let's set only the top level filesystem jailed
# the children should follow ia inheritance.
zfs set jailed=on ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/

for set in $caching_sets
do
   jexec $WEB_JAIL zfs set canmount=on           ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL zfs inherit mountpoint        ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/$set
   # allow freshports to rollback
   jexec $WEB_JAIL zfs allow freshports rollback ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL zfs mount                     ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL chown www:freshports /var/db/freshports/cache/$set
   jexec $WEB_JAIL chmod g+w            /var/db/freshports/cache/$set


   # this snapshot must be last or you'll undo the chown above when you rollback
   jexec $WEB_JAIL zfs snapshot                  ${datazpool}/freshports/jailed/$WEB_JAIL/var/db/freshports/cache/$set@empty
done

# Enable the search log. This has always been a thing, and never really used.
jexec $WEB_JAIL touch                /var/db/freshports/cache/searchlog.txt
jexec $WEB_JAIL chown www:freshports /var/db/freshports/cache/searchlog.txt
jexec $WEB_JAIL chmod 0644           /var/db/freshports/cache/searchlog.txt

# I am not sure why this needs to be done, but when configuring x8dtu, it was required.
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/freshports/cache/html 
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/freshports/cache/spooling
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/freshports/message-queues
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/freshports/repos
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/ingress/message-queues
#zfs inherit mountpoint main_tank/freshports/$INGRESS_JAIL/var/db/ingress/repos
#
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/freshports/cache/html 
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/freshports/cache/spooling
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/freshports/message-queues
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/freshports/repos
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/ingress/message-queues
#zfs mount main_tank/freshports/$INGRESS_JAIL/var/db/ingress/repos

jexec $WEB_JAIL mkdir                /var/db/freshports/cache/html
