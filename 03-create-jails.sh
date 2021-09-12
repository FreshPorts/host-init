#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

if [ ! -z ${INGRESS_JAIL} ]; then
  echo creating ${INGRESS_JAIL}
  mkjail create -v ${VERSION}-RELEASE -j ${INGRESS_JAIL} -f ingress
fi

if [ ! -z ${WEB_JAIL} ]; then
  echo creating ${WEB_JAIL}
  mkjail create -v ${VERSION}-RELEASE -j ${WEB_JAIL} -f nginx
fi

if [ ! -z ${PG_JAIL} ]; then
  echo creating ${PG_JAIL}
  mkjail create -v ${VERSION}-RELEASE -j ${PG_JAIL} -f default
fi
