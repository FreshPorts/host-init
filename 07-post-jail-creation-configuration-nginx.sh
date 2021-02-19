#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

zfs set jailed=on ${datazpool}/freshports/$WEB_JAIL/var/db/freshports

jexec $WEB_JAIL zfs set mountpoint=/var/db/freshports/cache ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache

for set in $caching_sets
do
   zfs set jailed=on                             ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL zfs set canmount=on           ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL zfs inherit mountpoint        ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set
   # allow freshports to rollback
   jexec $WEB_JAIL zfs allow freshports rollback ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL zfs mount                     ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set
   jexec $WEB_JAIL chown www:freshports /var/db/freshports/cache/$set

   # this snapshot must be last or you'll undo the chown above when you rollback
   jexec $WEB_JAIL zfs snapshot                  ${datazpool}/freshports/$WEB_JAIL/var/db/freshports/cache/$set@empty
done

