#!/bin/sh

. /usr/local/etc/host-init/jail-vars.sh

#
# This script creates filesystems which would not be created by the mkjail scripts
# but are required by the jails which will be created.
#

# create the jails top level dataset
zfs create -o mountpoint=${jailroot} ${jailzpool}/jails

# create the releases dataset
zfs create -o mountpoint=${freebsdreleases} ${freebsdzpool}/freebsd_releases

# create the flavours dir
mkdir -p ${freebsdreleases}/flavours/default/etc

# use our resolve there
if [ ! -r ${freebsdreleases}/flavours/default/etc/resolv.conf ]
then
  cp /etc/resolv.conf ${freebsdreleases}/flavours/default/etc/
fi

if [ ! -z "${INGRESS_JAIL}" ]
then
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/freshports/cache/html
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/freshports/cache/spooling
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/freshports/message-queues
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/freshports/repos
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/ingress/message-queues
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/ingress/repos
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${INGRESS_JAIL}/var/db/ingress_svn/message_queues
zfs snapshot ${datazpool}/freshports/${INGRESS_JAIL}/var/db/freshports/cache/html@empty
fi

# One day, you might ask, why put var/db/freshports in the filesystem name? Why not shorter?
# Things change. Today we are only caching for the freshports user. Tomorrow, it might be another location.
# Keep it like this, it's a few empty filesystems, but the hierarchy is there.
zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${WEB_JAIL}/var/db/freshports/cache

if [ ! -z "${WEB_JAIL}" ]
then
for set in $caching_sets
do
  zfs create -p -o canmount=noauto -o mountpoint=none ${datazpool}/freshports/${WEB_JAIL}/var/db/freshports/cache/$set
done
fi