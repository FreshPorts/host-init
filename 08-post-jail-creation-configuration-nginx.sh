#!/bin/sh -x

. /usr/local/bin/jails/jail-vars.sh

# allow freshports to rollback

jexec nginx01 zfs allow freshports rollback ${freebsdzpool}/freshports/nginx01/cache/packages
jexec nginx01 zfs allow freshports rollback ${freebsdzpool}/freshports/nginx01/cache/ports
