# FreshPorts Ansible configuration

## Ansible configuration:

Assuming you are configuring r720-02-nginx01, a jail on r720-02.int.unixathome.org
NOTE: the jail can be named anything you want. r720-02-nginx01 is used only by 
      Ansible.

## Add this to ~/.ssh/config

    host r720-02-freshports-nginx01
      user minion
      ProxyJump minion@r720-02.int.unixathome.org
      hostname 127.163.0.80
      ForwardAgent yes

## Copy this template

    svn cp TEMPLATE-freshports-nginx r720-02-freshports-nginx01

Adjust value contained therein

## `hosts` file

add `r720-02-nginx01` to these hostgroups in the `hosts` file:

* `logcheck`
* `nrpe`
* `freshports_websites_new`
* `freshports_websites`
* `freshports_modules`

## New(?) hostgroup

Create (if required) a new hostgroup (note all hyphens must be converted to underscrores):


    [r720_02.int.unixathome.org_jails]
    r720-02-freshports-nginx01


## Certificates

create and install certificates to `/usr/local/etc/ssl`



