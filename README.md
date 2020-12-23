# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail)

## Before running the scripts

* create the certs
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
    ln -s ~/src/host-init/mkjail.conf .

    cd ~/src/host-init

    # Add this line or something similar to /etc/rc.conf so the above copied
    # file is invoked at startup.
    #
    # rc_conf_files="${rc_conf_files} /etc/rc.conf.freshports"

    sudo ./01-jail-fileset-initialize.sh

    # This creates the jails which will be later configured by Ansible
    sudo ./03-create-jails.sh

    sudo cp -i jail.conf /etc/jail.conf

    sudo ./04-start-jails.sh

    sudo ./05-prepare-jails-for-ansible.sh
    sudo ./06-install-local-files.sh

    # if you haven't already, do the Ansible configuration outlines in
    # [Ansible.md](Ansible.md)

    # Switch over to the ansible host and run:


    # For postgresql hosts:
    #
    # ansible-playbook jail-postgresql.yml --limit=pg02.int.unixathome.org

    #
    # use pg_hba.conf file as a template for additiions to the
    # pg_hba.conf file on the PostgreSQL server.
    # Look in roles/postgresql-server/templates/hosts/SERVERNAME/pg_hba.conf.j2
    #

    # run the ansible scripts. The following scripts depend upon users
    # created by that process
    #

    # For ingress hosts:

    # ansible-playbook freshports-ingress.yml --limit=r720-02-freshports-ingress01

    #
    # key for the ingress jail
    #
    sudo jexec ingress01
    mkdir /usr/local/etc/ssl
    cd /usr/local/etc/ssl
    set CERTNAME=r720-02-ingress01.int.unixathome.org
    touch ${CERTNAME}.key
    chmod 400 ${CERTNAME}.key


    # copy the cert key into that file

    # then leave the jail
    exit

    # pull in the cert for that key above
    sudo jexec -U anvil ingress01 /usr/local/bin/cert-puller

    # ansible-playbook freshports-configuration-ingress.yml --limit=r720-02-freshports-ingress01


    # For nginx hosts:
    # ansible-playbook freshports-website.yml --limit=r720-02-freshports-nginx01

    #
    # key for the nginx jail
    #
    sudo jexec nginx01
    mkdir /usr/local/etc/ssl
    cd /usr/local/etc/ssl
    set CERTNAME=r720-02.freshports.org
    touch ${CERTNAME}.key
    chmod 440 ${CERTNAME}.key
    chown root:www ${CERTNAME}.key

    # copy the cert key into that file

    # then leave the jail
    exit

    # pull in the cert for that key above
    sudo jexec -U anvil nginx01 /usr/local/bin/cert-puller

    # ansible-playbook freshports-configuration-website.yml --limit=r720-02-freshports-nginx01
    #

    # for the mx-ingress jail
    ansible-playbook freshports-mx-ingress-mailserver.yml --limit=r720-02-freshports-mx-ingress04

    #
    # key for the mx jail
    #
    sudo jexec mx-ingress04
    mkdir /usr/local/etc/ssl
    cd /usr/local/etc/ssl
    set CERTNAME=r720-02-mx-ingress04.int.unixathome.org.
    touch ${CERTNAME}.key
    chmod 400 ${CERTNAME}.key

    # copy the cert key into that file

    # then leave the jail
    exit

    # pull in the cert for that key above
    sudo jexec -U anvil mx-ingress04 /usr/local/bin/cert-puller



    sudo service jail stop

    # amend /etc/jail.conf and uncomment things which say AFTER CONFIG

    sudo service jail start

    sudo ./07-mount-external-datasets
    sudo ./08-newsyslog.conf


    sudo ./18-post-jail-creation-configuration-ingress.sh
    sudo ./19-post-jail-creation-configuration-nginx.sh

    # This FreshPorts instance should now be running
