#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

jexec ingress01 zfs set canmount=on ${jailzpool}/freshports/ingress01/cache/html

#jexec nginx01 zfs set mountpoint=/var/db/freshports/cache/packages ${jailzpool}/freshports/nginx01/cache/packages
#jexec nginx01 zfs set mountpoint=/var/db/freshports/cache/ports    ${jailzpool}/freshports/nginx01/cache/ports
jexec ingress01 zfs inherit mountpoint ${jailzpool}/freshports/ingress01/cache/html

# this will also mount the dataset
jexec ingress01 zfs set mountpoint=/var/db/freshports/cache/html ${jailzpool}/freshports/ingress01/cache/html

# no need to mount, the set mountpoint' above will do that.
#jexec ingress01 zfs mount ${jailzpool}/freshports/ingress01/cache/html

# we need www on the ingress side so we have the correct permissions on the webserver
jexec ingress01 chown -R www:freshports /var/db/freshports/cache

# this is mounted nullfs in the webserver
jexec ingress01 chown -R freshports:freshports /var/db/freshports/cache/html

jexec ingress01 chmod 0755 /var/db/freshports/cache
# the html directory is only cleared on the ingress side
jexec ingress01 chmod 0755 /var/db/freshports/cache/html

# allow freshports to rollback

jexec ingress01 zfs allow freshports rollback ${jailzpool}/freshports/ingress01/cache

# set correct permission on ~ingress/repos directory
# this is a mountpoint for a zfs file system

jexec ingress01 chown ingress:ingress /var/db/ingress/repos
