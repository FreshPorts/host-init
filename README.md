# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail)

## Before running the scripts

* add the A and PTR records for the new hosts
* add the grant permissions for TXT records for Let's Encrypt
* create the certs
* name them after the host which will be used to access this FreshPorts host
* Follow the [Ansible.md](Ansible.md) instructions to prepare the hosts

## The scripts

These are the configuration items for the scripts below:

    export INGRESS_CERTNAME=aws-1-ingress01.freshports.org
    # this cert will also have names for freshports.org and www.freshports.org
    export NGINX_CERTNAME=aws-1.freshports.org
    export MXINGRESS_CERTNAME=mx-ingress04.freshports.org

These are the scripts to run after the above.

1.  Configure the host itself by running this Ansible script. This will
install the prerequisite packages such as git, unbound, ntpd, etc.

        ansible-playbook freshports-host.yml --limit=aws-1.freshports.org

1.  Get the `host-init` scripts
    
        mkdir ~/src
        cd ~/src
        git clone https://github.com/FreshPorts/host-init
        cd host-init
        sudo mkdir /usr/local/etc/host-init
        sudo cp -i jail-vars.sh.sample /usr/local/etc/host-init/jail-vars.sh

        cd ~/src/mkjail/src/etc
        ln -s ~/src/host-init/mkjail.conf .

1.  Start runnig the configuration scripts

        cd ~/src/host-init

        sudo ./00-rc.conf-settings
        sudo ./01-jail-fileset-initialize.sh

        # start stuff on the host which are needed by the jails
        # eg. unbound
        sudo ./02-start-required-services

1.  Create the jails

        # This creates the jails which will be later configured by Ansible
        sudo ./03-create-jails.sh

        sudo cp -i jail.conf /etc/jail.conf

1.  Start the jails and configure them for running Ansible

        sudo ./04-start-jails.sh

        sudo ./05-prepare-jails-for-ansible.sh

        # if you haven't already, do the Ansible configuration outlined in
        # [Ansible.md](Ansible.md)

1.  Switch over to the ansible host and run some or all of these commands


1. For postgresql hosts:

        ansible-playbook jail-postgresql.yml --limit=pg02.int.unixathome.org

        #
        # use pg_hba.conf file as a template for additiions to the
        # pg_hba.conf file on the PostgreSQL server.
        # Look in roles/postgresql-server/templates/hosts/SERVERNAME/pg_hba.conf.j2
        #

        # run the ansible scripts. The following scripts depend upon users
        # created by that process
        #

1. For ingress hosts:

        ansible-playbook freshports-ingress.yml --limit=aws-1.freshports-ingress01

        #
        # key for the ingress jail
        #
        sudo jexec ingress01 mkdir /usr/local/etc/ssl
        sudo jexec ingress01 touch /usr/local/etc/ssl/${INGRESS_CERTNAME}.key
        sudo jexec ingress01 chmod 440 /usr/local/etc/ssl/${INGRESS_CERTNAME}.key
        sudo jexec ingress01 chown root:www /usr/local/etc/ssl/${INGRESS_CERTNAME}.key

        # copy the cert key into that file
        sudo jexec ingress01 sudoedit /usr/local/etc/ssl/${INGRESS_CERTNAME}.key


1.  For nginx hosts:

        ansible-playbook freshports-website.yml --limit=aws-1.freshports-nginx01

        #
        # key for the nginx jail
        #
        sudo jexec nginx01 mkdir /usr/local/etc/ssl
        sudo jexec nginx01 touch /usr/local/etc/ssl/${NGINX_CERTNAME}.key
        sudo jexec nginx01 chmod 440 /usr/local/etc/ssl/${NGINX_CERTNAME}.key
        sudo jexec nginx01 chown root:www /usr/local/etc/ssl/${NGINX_CERTNAME}.key

        # copy the cert key into that file
        sudo jexec nginx01 sudoedit /usr/local/etc/ssl/${NGINX_CERTNAME}.key

        # this will attempt to start nginx, which will fail, because it does
        # not have the certificate yet, but it is all configured to go.
        # that is OK, because it is the last step performed.
        # we could just run cert-puller first.

1. for the mx-ingress jail

        ansible-playbook freshports-mx-ingress-mailserver.yml --limit=aws-1.freshports-mx-ingress04

        #
        # key for the mx jail
        #
        sudo jexec mx-ingress04 mkdir /usr/local/etc/ssl
        sudo jexec mx-ingress04 touch /usr/local/etc/ssl/${MXINGRESS_CERTNAME}.key
        sudo jexec mx-ingress04 chmod 440 /usr/local/etc/ssl/${MXINGRESS_CERTNAME}.key
        sudo jexec mx-ingress04 chown root:www /usr/local/etc/ssl/${MXINGRESS_CERTNAME}.key


        # copy the cert key into that file
        sudo jexec mx-ingress04 sudoedit /usr/local/etc/ssl/${MXINGRESS_CERTNAME}.key


1. With the required packages installed, try fetching certs etc:

        # This will configure cert-puller.conf, run `cert-puller -s` to get
        # the sudo permissions, and run `cert-puller`
        sudo ./06-install-local-files.sh

1. With the certs downloaded and installed, we can do the final configurations.

        ansible-playbook freshports-configuration-ingress.yml --limit=aws-1.freshports-ingress01

        ansible-playbook freshports-configuration-website.yml --limit=aws-1.freshports-nginx01

1. Now that the jails have been configured, we can mount all the filesystems

        sudo service jail stop

        sudoedit /etc/jail.conf
        # uncomment things which say AFTER CONFIG

1.  Mount the previously unmounted filesystems
        # this will mount the repos dir
        # populate the repos:
        #
        # * ingress - git src, ports, doc, ports-quarterly
        # * ingress_svn = ports
        # * freshports - git ports, svn ports
        #

        sudo ./07-mount-external-datasets

1.  Start the jails again

        sudo service jail start



1.  Remember to rotat log files

        # the jails need to be started for this one
        sudo ./08-newsyslog.conf

1.  Some post configuration

        sudo ./18-post-jail-creation-configuration-ingress.sh
        sudo ./19-post-jail-creation-configuration-nginx.sh

This FreshPorts instance should now be running
