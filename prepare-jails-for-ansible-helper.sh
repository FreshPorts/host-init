#!/bin/sh -x

# This configures the jail for use by ansible
# copy this into the jail, then run it there.

pw useradd -n minion -s /bin/sh -m -d /usr/home/minion -G wheel
mkdir /usr/home/minion/.ssh
chown minion:minion /usr/home/minion/.ssh
chmod 0700 /usr/home/minion/.ssh

cat << EOF > /usr/home/minion/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQLPHI9EjQGBuMEiL54v92cOiWizHLuf4K/g1NYJpJBJO1Dks74Yb27rSDFQLQQeMfch0bXmPkKk+QNwAwNrQARMSCW/4xmLUDAJqiZzaUT3xIrsdm2ruHAoYHaa1HAQrD2K50XSpvIxAlpULDGfnV/SFUe5rHXUgNRX/ePMd3Mr955NCVlF3cylXgzS5QA/ILtmuMzzwSn2IqoOBHK87CeiNR010sUwwrb8ap2R657mb7hXW1zFuZzdk7F7JNYKMeljLiTHbDZAbTpTtiUqvXHFIPLeCicAz5/F8bPZGNBV+iKJy/iOLg8zq+xTIWD7ORotRJ7NfBIyQ9ZUbVsHFM+YOXQCleXky3S25IqD7WaCOCUxgiBqZqfeH7naNqkGE5GglTYw6+ZdtWwOLdIh+CqUEwmC9G84reVgu5V5hrnlJ4QN0prRrCTBZo/plxKDYckMP+Z9/gL/juuN3AazXAANgTocUCi1q9/ACGEW9WjQr8vtHFVzCQzMPSRYV1C2dqgadA4e0U5LtOuNI4yKFItnStwCPkfy0ODX76KgXyl8g4unBc0opk197MfXlmQlbCWeRdhbP4u0NqwJzuC33d0XSsGDFQpEO/ml8M52IM9AF6uy8yslzH2KDyO77AQTP58pMWobHIPQvxFTpwazmOvxfs3QJNwJTILsVwTvKZhS8w== /root/.ssh/id_rsa
EOF

chown minion:minion /usr/home/minion/.ssh/authorized_keys
chmod 0600          /usr/home/minion/.ssh/authorized_keys

cat << EOF > /etc/ssl/slocum.unixathome.org.cert
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

mkdir -p /usr/local/etc/pkg/repos
echo "FreeBSD: { enabled: no }" > /usr/local/etc/pkg/repos/FreeBSD.conf
cat << EOF > /usr/local/etc/pkg/repos/local.conf
local: {
   url: "pkg+http://fedex.unixathome.org/packages/%%REPO_TREE%%/"
   mirror_type: "srv",
   signature_type: "PUBKEY",
   pubkey: "/etc/ssl/slocum.unixathome.org.cert",   
   enabled: true
}
EOF

env ASSUME_ALWAYS_YES=YES pkg -4 install pkg

pkg -4 install -y sudo python security/pam_ssh_agent_auth ca_root_nss
#pkg -4 install -y python
#pkg -4 install -y security/pam_ssh_agent_auth
#pkg -4 install -y ca_root_nss

cat << EOF > /usr/local/etc/sudoers
Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_AUTH_SOCK",timestamp_timeout=0
root ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
@includedir /usr/local/etc/sudoers.d
EOF


cat << EOF > /usr/local/etc/pam.d/sudo
auth sufficient /usr/local/lib/pam_ssh_agent_auth.so file=~/.ssh/authorized_keys
auth required pam_deny.so
account include system
session required pam_permit.so
EOF
