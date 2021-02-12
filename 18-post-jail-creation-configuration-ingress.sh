#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

#jexec ${INGRESS_JAIL} zfs set canmount=on ${jailzpool}/freshports/${INGRESS_JAIL}/cache/html

#jexec ${WEB_JAIL} zfs set mountpoint=/var/db/freshports/cache/packages ${jailzpool}/freshports/${WEB_JAIL}/cache/packages
#jexec ${WEB_JAIL} zfs set mountpoint=/var/db/freshports/cache/ports    ${jailzpool}/freshports/${WEB_JAIL}/cache/ports
#jexec ${INGRESS_JAIL} zfs inherit mountpoint ${jailzpool}/freshports/${INGRESS_JAIL}/cache/html

# this will also mount the dataset
#jexec ${INGRESS_JAIL} zfs set mountpoint=/var/db/freshports/cache/html ${jailzpool}/freshports/${INGRESS_JAIL}/cache/html

# no need to mount, the set mountpoint' above will do that.
#jexec ${INGRESS_JAIL} zfs mount ${jailzpool}/freshports/${INGRESS_JAIL}/cache/html

# we need www on the ingress side so we have the correct permissions on the webserver
#jexec ${INGRESS_JAIL} chown -R www:freshports /var/db/freshports/cache

# this is mounted nullfs in the webserver
#jexec ${INGRESS_JAIL} chown -R freshports:freshports /var/db/freshports/cache/html

# XXX Do we need this?
#jexec ${INGRESS_JAIL} chmod 0755 /var/db/freshports/cache
# the html directory is only cleared on the ingress side
#jexec ${INGRESS_JAIL} chmod 0755 /var/db/freshports/cache/html

# allow freshports to rollback
# DOES the code do a rollback? I think not
#jexec ${INGRESS_JAIL} zfs allow freshports rollback ${jailzpool}/freshports/${INGRESS_JAIL}/cache

# set correct permission on ~ingress/repos directory
# this is a mountpoint for a zfs file system

#jexec ${INGRESS_JAIL} chown ingress:ingress /var/db/ingress/repos
