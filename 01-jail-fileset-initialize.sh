#!/bin/sh

. /usr/local/etc/host-init/jail-vars.sh

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
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/ingress01/repos

zfs snapshot ${freebsdzpool}/freshports/ingress01/cache/html@empty

zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01/cache
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01/cache/ports
zfs create -o canmount=off -o mountpoint=none ${freebsdzpool}/freshports/nginx01/cache/packages

zfs snapshot ${freebsdzpool}/freshports/nginx01/cache/ports@empty
zfs snapshot ${freebsdzpool}/freshports/nginx01/cache/packages@empty

zfs set jailed=on ${freebsdzpool}/freshports/nginx01/cache/ports
zfs set jailed=on ${freebsdzpool}/freshports/nginx01/cache/packages
