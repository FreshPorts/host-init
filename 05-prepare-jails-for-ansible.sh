#!/bin/sh
. /usr/local/etc/host-init/jail-vars.sh

for jail in ${JAILS}
do
  echo preparing $jail
  cp -a prepare-jails-for-ansible-helper.sh ${jailroot}/$jail/
  jexec $jail /prepare-jails-for-ansible-helper.sh
  rm ${jailroot}/$jail/prepare-jails-for-ansible-helper.sh
done
