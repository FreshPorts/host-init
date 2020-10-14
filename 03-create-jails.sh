#!/bin/sh
. /usr/local/etc/host-init/jail-vars.sh

JAILS="ingress01 nginx01"
for jail in ${JAILS}
do
  echo creatig $jail
  cd $mkjail_path
  ./src/bin/mkjail create -v 12.1-RELEASE -j ${jail} -f default
done

