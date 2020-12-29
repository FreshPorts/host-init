#!/bin/sh
. /usr/local/etc/host-init/jail-vars.sh

for jail in ${JAILS}
do
  echo starting $jail
  service jail start $jail
done

