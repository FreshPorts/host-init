#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

# this is where we install
# * certs

# which jails have certs and need cert-puller configured

JAILS="ingress01 nginx01 mx-ingress04"
for jail in $JAILS
do
  mkdir -p ${jailroot}/$jail/usr/local/etc/anvil
  cp cert-puller.conf.template ${jailroot}/$jail/usr/local/etc/anvil/cert-puller.conf
done

# this is harder to put into a for loop because the jail name and the cert name do corresponds

sed -i '' -e 's/%%MYCERTS%%/aws-1-ingress01.freshports.org/g' ${jailroot}/ingress01/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RESTART%%/SERVICES_RESTART="postfix"/g'               ${jailroot}/ingress01/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RELOAD%%//g'                       ${jailroot}/ingress01/usr/local/etc/anvil/cert-puller.conf

sed -i '' -e 's/%%MYCERTS%%/aws-1-nginx01.freshports.org/g'   ${jailroot}/nginx01/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RESTART%%//g'                      ${jailroot}/nginx01/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RELOAD%%/SERVICES_RELOAD="nginx"/g'                  ${jailroot}/nginx01/usr/local/etc/anvil/cert-puller.conf

sed -i '' -e 's/%%MYCERTS%%/mx-ingress04.freshports.org/g'    ${jailroot}/mx-ingress04/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RESTART%%/SERVICES_RELOAD="postfix"/g'               ${jailroot}/mx-ingress04/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e 's/%%SERVICES_RELOAD%%//g'                       ${jailroot}/mx-ingress04/usr/local/etc/anvil/cert-puller.conf

# now set the sudo permissions for each jail

JAILS="ingress01 nginx01 mx-ingress04"
for jail in $JAILS
do
  # we have to create it because sudo has not yet been installed
  mkdir -p ${jailroot}/$jail/usr/local/etc/sudoers.d/
  sudo jexec ingress01 /usr/local/bin/cert-puller -s > ${jailroot}/$jail/usr/local/etc/sudoers.d/anvil
done
