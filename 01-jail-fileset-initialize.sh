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
cp /etc/resolv.conf ${freebsdreleases}/flavours/default/etc/

zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/ingress01
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/ingress01/cache
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/ingress01/cache/html

# these is noauto because it gets mounted/umounted by jail.conf
# -p because the parents will not exist
zfs create -po canmount=noauto -o mountpoint=none ${freebsdzpool}/freshports/ingress01/ingress/repos
zfs create -po canmount=noauto -o mountpoint=none ${freebsdzpool}/freshports/ingress01/freshports/repos

zfs snapshot ${freebsdzpool}/freshports/ingress01/cache/html@empty

zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01/cache

for set in $caching_sets
do
  zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01/cache/$set
done
