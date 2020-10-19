#!/bin/sh

. /usr/local/etc/host-init/jail-vars.sh

cd $mkjail_path

echo creating ingress01
./src/bin/mkjail create -v 12.1-RELEASE -j ingress01 -f ingreee

echo creating nginx01
./src/bin/mkjail create -v 12.1-RELEASE -j nginx01 -f nginx
