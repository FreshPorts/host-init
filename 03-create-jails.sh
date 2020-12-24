#!/bin/sh

. /usr/local/etc/host-init/jail-vars.sh

cd $mkjail_path

echo creating ingress01
./src/bin/mkjail create -v ${VERSION}-RELEASE -j ingress01 -f ingress

echo creating nginx01
./src/bin/mkjail create -v ${VERSION}-RELEASE -j nginx01 -f nginx

#
# 04 here, because we mx-ingress hostnames are public and we already
# have both 01 and 02 and 03.
#
echo creating mx-ingress04
./src/bin/mkjail create -v ${VERSION}-RELEASE -j mx-ingress04 -f default
