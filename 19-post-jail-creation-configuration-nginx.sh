#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

jexec nginx01 zfs set mountpoint=/var/db/freshports/cache ${freebsdzpool}/freshports/nginx01/cache

for set in $caching_sets
do
   zfs set jailed=on                           ${freebsdzpool}/freshports/nginx01/cache/$set
   jexec nginx01 zfs set canmount=on           ${freebsdzpool}/freshports/nginx01/cache/$set
   jexec nginx01 zfs inherit mountpoint        ${freebsdzpool}/freshports/nginx01/cache/$set
   # allow freshports to rollback
   jexec nginx01 zfs allow freshports rollback ${freebsdzpool}/freshports/nginx01/cache/$set
   jexec nginx01 zfs mount                     ${freebsdzpool}/freshports/nginx01/cache/$set
   jexec nginx01 chown www:freshports /var/db/freshports/cache/$set

   # this snapshot must be last or you'll undo the chown above when you rollback
   jextc nginx01 zfs snapshot                  ${freebsdzpool}/freshports/nginx01/cache/$set@empty
done

jexec nginx01 mkdir                /var/db/freshports/cache/spooling
jexec nginx01 chown www:freshports /var/db/freshports/cache/spooling
