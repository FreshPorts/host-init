#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

jexec ingress01 zfs set canmount=on ${freebsdzpool}/freshports/ingress01/cache/html

jexec ingress01 zfs set mountpoint=/var/db/freshports/cache/packages ${freebsdzpool}/freshports/ingress01/cache/packages
jexec ingress01 zfs set mountpoint=/var/db/freshports/cache/ports    ${freebsdzpool}/freshports/ingress01/cache/ports
#jexec ingress01 zfs inherit mountpoint ${freebsdzpool}/freshports/ingress01/cache/html

#jexec ingress01 zfs mount ${freebsdzpool}/freshports/ingress01/cache/html

# we need www on the ingress side so we have the correct permissions on the webserver
jexec ingress01 chown -R www:freshports /var/db/freshports/cache

# this is mounted nullfs in the webserver
jexec ingress01 chown -R freshports:freshports /var/db/freshports/cache/html

jexec ingress01 chmod 0755 /var/db/freshports/cache
# the html directory is only cleared on the ingress side
jexec ingress01 chmod 0755 /var/db/freshports/cache/html

# allow freshports to rollback

jexec ingress01 zfs allow freshports rollback ${freebsdzpool}/freshports/ingress01/cache
