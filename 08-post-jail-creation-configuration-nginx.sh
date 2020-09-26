#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

jexec nginx01 zfs set canmount=on ${freebsdzpool}/freshports/nginx01/cache/packages
jexec nginx01 zfs set canmount=on ${freebsdzpool}/freshports/nginx01/cache/ports

jexec nginx01 zfs set mountpoint=/var/db/freshports/cache ${freebsdzpool}/freshports/nginx01/cache
jexec nginx01 zfs inherit mountpoint ${freebsdzpool}/freshports/nginx01/cache/packages
jexec nginx01 zfs inherit mountpoint ${freebsdzpool}/freshports/nginx01/cache/ports

jexec nginx01 zfs mount ${freebsdzpool}/freshports/nginx01/cache/packages
jexec nginx01 zfs mount ${freebsdzpool}/freshports/nginx01/cache/ports

# allow freshports to rollback

jexec nginx01 zfs allow freshports rollback ${freebsdzpool}/freshports/nginx01/cache/packages
jexec nginx01 zfs allow freshports rollback ${freebsdzpool}/freshports/nginx01/cache/ports

jexec nginx01 chown www:freshports /var/db/freshports/cache/ports
jexec nginx01 chown www:freshports /var/db/freshports/cache/packages

jexec nginx01 mkdir /var/db/freshports/cache/spooling
jexec nginx01 chown www:freshports /var/db/freshports/cache/spooling
