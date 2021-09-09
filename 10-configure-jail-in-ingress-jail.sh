#!/bin/sh -x

. /usr/local/etc/host-init/jail-vars.sh

jexec ${INGRESS_JAIL} zfs set mountpoint=/jails         main_tank/freshports/jailed/ingress01/jails
jexec ${INGRESS_JAIL} zfs set mountpoint=/var/db/mkjail main_tank/freshports/jailed/ingress01/mkjail

jexec ${INGRESS_JAIL} zfs mount main_tank/freshports/jailed/ingress01/jails
jexec ${INGRESS_JAIL} zfs mount main_tank/freshports/jailed/ingress01/mkjail

jexec ${INGRESS_JAIL} pkg install -y mkjail

cat << EOF > ${jailroot}/${INGRESS_JAIL}/usr/local/etc/mkjail.conf
# mkjail config file

# Set your zpool name
# New filesystems are created in this pool.
ZPOOL="${jailzpool}"

# Set the jail dataset name (without the zpool name).
# For example, jail foo will be created in \$ZPOOL/\$JAILDATASET/foo
# DEFAULT: jails
JAILDATASET="freshports/jailed/${INGRESS_JAIL}/jails"

# mkjail will create $ZPOOL/$MKJAILDATASET/${VERSION}
# by default, this is mkjail
MKJAILDATASET="freshports/jailed/${INGRESS_JAIL}/mkjail"

# Set jail root filesystem path.
# This is where the jails are mounted.
# DEFAULT: /jails
JAILROOT="/jails"

# The SETS which you want extracted into each new jail.
#
# options include: base-dbg, base, kernel-dbg, kernel, lib32-dbg, lib32, ports, src tests
# DEFAULT: base
#
# NOTE: src is always downloaded, regardless. It is needed when upgrading in
# order to do a proper 3-way merge.
SETS="base"
EOF

jexec ${INGRESS_JAIL} mkjail create -a amd64 -j freshports -v 13.0-RELEASE

jexec ${INGRESS_JAIL} sysrc jail_enable="YES"

cat << EOF > ${jailroot}/${INGRESS_JAIL}/etc/jail.conf
exec.start = "/bin/sh /etc/rc";
exec.stop  = "/bin/sh /etc/rc.shutdown";
exec.clean;
mount.devfs;
path = /jails/\$name;
allow.raw_sockets;
securelevel = 2;
exec.consolelog="/var/tmp/jail-\$name";
 
host.hostname = "\$name\$(hostname)";
 
persist;
freshports {
    host.hostname = "freshports";
 
    ip4 = inherit;
    persist;
 
    devfs_ruleset=0;
 
    allow.mount=true;
    enforce_statfs=1;
    allow.mount.devfs;
    allow.mount.procfs;
}
EOF

mkdir -p ${jailroot}/${INGRESS_JAIL}/jails/freshports/usr/local/etc/pkg/repos
echo "FreeBSD: { enabled: no }" > ${jailroot}/${INGRESS_JAIL}/jails/freshports/usr/local/etc/pkg/repos/FreeBSD.conf

cat << EOF > ${jailroot}/${INGRESS_JAIL}/jails/freshports/usr/local/etc/pkg/repos/local.conf
local: {
   url: "pkg+http://fedex.unixathome.org/packages/13amd64-default-primary/"
   mirror_type: "srv",
   signature_type: "PUBKEY",
   pubkey: "/etc/ssl/slocum.unixathome.org.cert",   
   enabled: true
}
EOF


cat << EOF > ${jailroot}/${INGRESS_JAIL}/jails/freshports/etc/ssl/slocum.unixathome.org.cert
-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAuveHTXwrwGmdWG6oFWgN
R/7bOQiQIE9iFmXmy4/MX9+01zMh2mjTfIOFe8IE1QqOK7X5EkVqhIdHCFg1Cg/x
Gl5oxxQEhp/HQbtVN7pNcpXKIGl0t5sFcjwXQqXS1wb87JP+v6KuOSTCFzS3l/X2
XtOo5QJZtxuF7+IM2PZlYb8MDmhVxriPw0pWRiP8lyW2LV1dSrN+VFpllZYinfIv
Sr7sUArIVlHH+Ddrm5MWjqTsHid36og26NDmAQnfX96IBF1sXadSTxKy3YwCnEcv
L7mBJhNyTIULuSbknM9zP9amkrlyLhWl+SdRGRkcOmXwHgzbdZsL62OlkXYIgkB+
tK099ARziCSe+sclhgfjoixnXxk0h9gUU6h5BDafATvtP4KDmwDYQEXO/7OPS0/H
vHFLEWLExcbW6hF0fyy2aA/HTlX83bBqJ+evsFtcvyxNfDp7tnjus/oAmJ82IU4F
0ZmWMoJDeNznO+3iokHH0J8vxa4kd1hjoSaDh1+qOZCXGRcsqyDTgWQEdQ5Uy76j
c9NgCJqHqJyjPqsiIZmPJNGUh1f7VaSUT8a131X5dwj6kx02s55UGJeIlK6F1d1f
7+7pdfv4rzHK3iPlP1eXQlv8szGAxdDbkSFqLK6gIC8V/Mf0B0zN0aU1JZkaAvoH
GopjN8IyF6fx/5yN9EAp8GUCAwEAAQ==
-----END PUBLIC KEY-----
EOF
 

cat << EOF > ${jailroot}/${INGRESS_JAIL}/jails/freshports/etc/resolv.conf
search unixathome.org int.unixathome.org
nameserver 127.163.0.53
EOF
 
 
cat << EOF > ${jailroot}/${INGRESS_JAIL}/jails/freshports/etc/rc.conf
cron_enable="NO"
syslogd_enable="NO"
sendmail_enable="NO"
sendmail_submit_enable="NO"
sendmail_outbound_enable="NO"
sendmail_msp_queue_enable="NO"
EOF

jexec ${INGRESS_JAIL} service jail start

#jexec ${INGRESS_JAIL} git clone https://git.FreeBSD.org/ports.git /jails/freshports/usr/ports
