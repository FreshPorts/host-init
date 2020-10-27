# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail)

## Before running the scripts

* create the certs
* copy .crt and .key files to
* name them after the host which will be used to access this FreshPorts host

## The scripts

These are the scripts to run after the above.

    mkdir ~/src
    cd ~/src
    git clone https://github.com/FreshPorts/host-init
    cd host-init
    sudo mkdir /usr/local/etc/host-init
    sudo cp -i jail-vars.sh.sample /usr/local/etc/host-init/jail-vars.sh
    sudo cp -i rc.conf.freshports /etc/

    cd ~/src/mkjail/src/etc
    sudo ln -s /usr/local/etc/host-init/jail-vars.sh mkjail.conf

    cd ~/src/host-init

    # Add this line or something similar to /etc/rc.conf so the above copied
    # file is invoked at startup.
    #
    # rc_conf_files="${rc_conf_files} /etc/rc.conf.freshports"

    sudo ./01-jail-fileset-initialize.sh
    # this configures the jail for use by ansible
    sudo ./03-create-jails.sh

    sudo sysrc jail_enable="YES"
    sudo cp -i jail.conf /etc/jail.conf

    sudo ./04-start-jails.sh
    sudo ./05-prepare-jails-for-ansible.sh
    sudo ./06-install-local-files.sh

    # if you haven't already, do the Ansible configuration outlines in
    # [Ansible.md](Ansible.md)

    #
    # use pg_hba.conf file as a template for additiions to the
    # pg_hba.conf file on the PostgreSQL server.
    # Look in roles/postgresql-server/templates/hosts/SERVERNAME/pg_hba.conf.j2
    #

    # run the ansible scripts. The following scripts depend upon users
    # created by that process
    #

    # For ingress hosts:
    # ansible-playbook freshports-scripts.yml --limit=aws-1.freshports-ingress01
    # ansible-playbook freshports-modules.yml --limit=aws-1.freshports-ingress01
    #

    # For nginx hosts:
    # ansible-playbook freshports-website.yml --limit=aws-1.freshports-nginx01
    # ansible-playbook freshports-configuration-website.yml --limit=aws-1.freshports-nginx01
    # 

    sudo service jail stop

    # amend /etc/jail.conf and uncomment things which say AFTER CONFIG

    sudo service jail start

    sudo ./07-post-jail-creation-configuration-ingress.sh
    sudo ./08-post-jail-creation-configuration-nginx.sh

    # This FreshPorts instance should now be running
