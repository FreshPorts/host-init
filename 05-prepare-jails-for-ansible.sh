#!/bin/sh -x
. /usr/local/etc/host-init/jail-vars.sh

for jail in ${JAILS}
do
  echo preparing $jail

  # this seems like an odd place to do this.
  # It seems only the mx-ingress gets a /etc/resolv.conf which is generated by resolvconf
  jexec $jail sysrc resolv_enable="NO"

  cp -a prepare-jails-for-ansible-helper.sh ${jailroot}/$jail/

  # adjust the repo on a per-jail basis
  eval repo_tree=\$${jail}_REPO_TREE
  sed -i '' -e "s#%%REPO_TREE%%#$repo_tree#g" ${jailroot}/$jail/prepare-jails-for-ansible-helper.sh

  # bootstrap cannot run from a non-FreeBSD repo
  jexec $jail env ASSUME_ALWAYS_YES=YES pkg -4 bootstrap

  jexec $jail /prepare-jails-for-ansible-helper.sh
  rm ${jailroot}/$jail/prepare-jails-for-ansible-helper.sh
done

