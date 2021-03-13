#!/bin/sh

. /usr/local/etc/host-init/jail-vars.sh

cd $mkjail_path

if [ ! -z ${INGRESS_JAIL} ]; then
  echo creating ${INGRESS_JAIL}
  ./src/bin/mkjail create -v ${VERSION}-RELEASE -j ${INGRESS_JAIL} -f ingress
fi

if [ ! -z ${WEB_JAIL} ]; then
  echo creating ${WEB_JAIL}
  ./src/bin/mkjail create -v ${VERSION}-RELEASE -j ${WEB_JAIL} -f nginx
fi

if [ ! -z ${MX_JAIL} ]; then
  echo creating ${MX_JAIL}
  ./src/bin/mkjail create -v ${VERSION}-RELEASE -j mx-ingress04 -f default
fi

if [ ! -z ${PG_JAIL} ]; then
  echo creating ${PG_JAIL}
  ./src/bin/mkjail create -v ${VERSION}-RELEASE -j ${PG_JAIL} -f default
fi
