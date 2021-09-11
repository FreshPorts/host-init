#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

# install the fstab files for the jails

if [ ! -z ${WEB_JAIL} ] ; then
  cp fstab/fstab.nginx   /etc/fstab.${WEB_JAIL}

  sed -i '' -e "s#%%JAIL_ROOT%%#$jailroot#g"                /etc/fstab.${WEB_JAIL}
  sed -i '' -e "s#%%JAIL_NAME_INGRESS%%#${INGRESS_JAIL}#g"  /etc/fstab.${WEB_JAIL}
  sed -i '' -e "s#%%JAIL_NAME_NGINX%%#${WEB_JAIL}#g"        /etc/fstab.${WEB_JAIL}
fi


# anvil configuration
# which jails have certs and need cert-puller configured

for jail in $JAILS
do
  mkdir -p ${jailroot}/$jail/usr/local/etc/anvil
  cp cert-puller.conf.template ${jailroot}/$jail/usr/local/etc/anvil/cert-puller.conf
done

# this is harder to put into a for loop because the jail name and the cert name do corresponds
# Yeah, where are the variables for the cert names?


# anvil configuration

if [ ! -z ${INGRESS_JAIL} ] ; then
  sed -i '' -e "s/%%MYCERTS%%/${INGRESS_JAIL_CERT}/g"                      ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RESTART%%/SERVICES_RESTART="postfix"/g"       ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RELOAD%%//g"                                  ${jailroot}/${INGRESS_JAIL}/usr/local/etc/anvil/cert-puller.conf
fi

if [ ! -z ${WEB_JAIL} ] ; then
  sed -i '' -e "s/%%MYCERTS%%/${WEB_JAIL_CERT}/g"                          ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RESTART%%//g"                                 ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RELOAD%%/SERVICES_RELOAD=\"nginx postfix\"/g" ${jailroot}/${WEB_JAIL}/usr/local/etc/anvil/cert-puller.conf
fi

if [ ! -z ${PG_JAIL} ] ; then
  sed -i '' -e "s/%%MYCERTS%%/${PG_JAIL_CERT}/g"                           ${jailroot}/${PG_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RESTART%%/SERVICES_RELOAD=\"postgresql\"/g"   ${jailroot}/${PG_JAIL}/usr/local/etc/anvil/cert-puller.conf
  sed -i '' -e "s/%%SERVICES_RELOAD%%//g"                                  ${jailroot}/${PG_JAIL}/usr/local/etc/anvil/cert-puller.conf
fi

# now set the sudo permissions for each jail

for jail in $JAILS
do
  # we have to create it because sudo has not yet been installed
  mkdir -p ${jailroot}/$jail/usr/local/etc/sudoers.d/

  # set sudo permissions for anvil re cert-puller
  jexec $jail /usr/local/bin/cert-puller -s > ${jailroot}/$jail/usr/local/etc/sudoers.d/anvil

  # pull down the certs
  jexec -U anvil $jail sh /usr/local/bin/cert-puller
done

# anvil configuration

zfs set canmount=off                                             main_tank/freshports/ingress01/var/db/freshports
zfs set mountpoint=${jailroot}/${INGRESS_JAIL}/var/db/freshports main_tank/freshports/ingress01/var/db/freshports

zfs inherit mountpoint main_tank/freshports/ingress01/var/db/freshports/cache/html
zfs inherit mountpoint main_tank/freshports/ingress01/var/db/freshports/cache/spooling
zfs inherit mountpoint main_tank/freshports/ingress01/var/db/freshports/message-queues
zfs inherit mountpoint main_tank/freshports/ingress01/var/db/freshports/repos


zfs set canmount=off                                             main_tank/freshports/ingress01/var/db/ingress
zfs set mountpoint=${jailroot}/${INGRESS_JAIL}/var/db/ingress    main_tank/freshports/ingress01/var/db/ingress

zfs inherit mountpoint main_tank/freshports/ingress01/var/db/ingress/message-queues
zfs inherit mountpoint main_tank/freshports/ingress01/var/db/ingress/repos


# aliases for dma - make sure mail for root gets out
for jail in $JAILS
do
  sed -i '' -e "s/# root:	me@my.domain/root:	dan@langille.org/g"                           ${jailroot}/${jail}/etc/aliases
done
