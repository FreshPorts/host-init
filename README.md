# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail)

    git clone https://github.com/FreshPorts/host-init
    cd host-init
    mkdir /usr/local/etc/host-init
    cp jail-vars.sh.sample /usr/local/etc/host-init/jail-vars.sh
    sudo ./01-jail-fileset-initialize.sh
    # this configures the jail for use by ansible
    sudo ./03-create-jails.sh
    sudo ./04-start-jails.sh
    sudo ./05-prepare-jails-for-ansible.sh

    # run the ansible scripts. The following scripts depend upon users
    # created by that process
    #
    # ansible-playbook freshports-scripts.yml --limit=aws-1.freshports-ingress01
    # ansible-playbook freshports-modules.yml --limit=aws-1.freshports-ingress01
    #
    # ansible-playbook freshports-website.yml --limit=aws-1.freshports-nginx01
    # 
    sudo ./07-post-jail-creation-configuration-ingress.sh
    sudo ./08-post-jail-creation-configuration-nginx.sh
