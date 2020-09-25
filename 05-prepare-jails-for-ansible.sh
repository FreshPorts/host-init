#!/bin/sh
. /usr/local/bin/jails/jail-vars.sh

JAILS="ingress01 nginx01"
for jail in ${JAILS}
do
  echo preparing $jail
  cd /usr/home/ec2-user/src/mkjail
  ./src/bin/mkjail create -v 12.1-RELEASE -j ${jail} -f default
  cd -
  service jail start $jail
  cp -a prepare-jails-for-ansible-helper.sh ${jailroot}/$jail/
  jexec $jail /prepare-jails-for-ansible-helper.sh
  rm ${jailroot}/$jail/prepare-jails-for-ansible-helper.sh
done

