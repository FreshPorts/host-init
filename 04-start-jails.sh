#!/bin/sh
. /usr/local/etc/host-init/jail-vars.sh

JAILS="ingress01 nginx01 mx-ingress04"
for jail in ${JAILS}
do
  echo starting $jail
  service jail start $jail
done

