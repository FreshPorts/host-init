#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

# install the fstab files for the jails

cp fstab/fstab.ingress /etc/fstab.${INGRESS_JAIL}
cp fstab/fstab.nginx   /etc/fstab.${WEB_JAIL}

# now massage that data
sed -i '' -e "s#%%JAIL_ROOT%%#$jailroot#g"          /etc/fstab.${INGRESS_JAIL}
sed -i '' -e "s#%%JAIL_NAME%%#${INGRESS_JAIL}#g"          /etc/fstab.${INGRESS_JAIL}

sed -i '' -e "s#%%JAIL_ROOT%%#$jailroot#g"          /etc/fstab.${WEB_JAIL}
sed -i '' -e "s#%%JAIL_NAME_INGRESS%%#${INGRESS_JAIL}#g"  /etc/fstab.${WEB_JAIL}
sed -i '' -e "s#%%JAIL_NAME_NGINX%%#${WEB_JAIL}#g"      /etc/fstab.${WEB_JAIL}

# which jails have certs and need cert-puller configured

for jail in $JAILS
do
  mkdir -p ${jailroot}/$jail/usr/local/etc/anvil
  cp cert-puller.conf.template ${jailroot}/$jail/usr/local/etc/anvil/cert-puller.conf
done

# this is harder to put into a for loop because the jail name and the cert name do corresponds
# Yeah, where are the variables for the cert names?

sed -i '' -e "s/%%MYCERTS%%/${INGRESS_JAIL_CERT}/g"                      ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RESTART%%/SERVICES_RESTART="postfix"/g"       ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RELOAD%%//g"                                  ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf

sed -i '' -e "s/%%MYCERTS%%/${WEB_JAIL_CERT}/g"                          ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RESTART%%//g"                                 ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RELOAD%%/SERVICES_RELOAD=\"nginx postfix\"/g" ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf

sed -i '' -e "s/%%MYCERTS%%/${MX_JAIL_CERT}/g"                           ${jailroot}/${MX_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RESTART%%/SERVICES_RELOAD=\"postfix\"/g"      ${jailroot}/${MX_JAIL}/usr/local/etc/anvil/cert-puller.conf
sed -i '' -e "s/%%SERVICES_RELOAD%%//g"                                  ${jailroot}/${MX_JAIL}/usr/local/etc/anvil/cert-puller.conf

# now set the sudo permissions for each jail

for jail in $JAILS
do
  # we have to create it because sudo has not yet been installed
  mkdir -p ${jailroot}/$jail/usr/local/etc/sudoers.d/

  # set sudo permissions for anvil re cert-puller
  sudo jexec $jail /usr/local/bin/cert-puller -s > ${jailroot}/$jail/usr/local/etc/sudoers.d/anvil

  # pull down the certs
  sudo jexec -U anvil $jail /usr/local/bin/cert-puller
done

