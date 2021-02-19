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

These are the scripts to run after the above.

1. Configure the host itself by running this Ansible script. This will
install the prerequisite packages such as git, unbound, ntpd, etc.

        ansible-playbook freshports-host.yml --limit=aws-1.freshports.org

1. Get the `host-init` scripts
    
        mkdir ~/src
        cd ~/src
        git clone https://github.com/FreshPorts/host-init
        cd host-init
        sudo mkdir /usr/local/etc/host-init
        sudo cp -i jail-vars.sh.sample /usr/local/etc/host-init/jail-vars.sh

	\# adjust the ZPOOL and JAILROOT to your requirements
        cd ~/src/mkjail/src/etc
        ln -s ~/src/host-init/mkjail.conf .

1. Start runnig the configuration scripts

        cd ~/src/host-init

        sudo ./00-rc.conf-settings
        sudo ./01-jail-fileset-initialize.sh

        # start stuff on the host which are needed by the jails
        # eg. unbound
        sudo ./02-start-required-services

1. Create the jails

        # This creates the jails which will be later configured by Ansible
        sudo ./03-create-jails.sh

        sudo cp -i jail.conf /etc/jail.conf

1. Start the jails and configure them for running Ansible

        sudo ./04-start-jails.sh

        sudo ./05-prepare-jails-for-ansible.sh

        # if you haven't already, do the Ansible configuration outlined in
        # Ansible.md

1. Switch over to the ansible host and run some or all of these commands

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

            ansible-playbook freshports-ingress-git.yml --limit=aws-1.freshports-ingress01

            # The following is run on the jail host
            # INGRESS_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bringing those variables into your shell: . /usr/local/etc/host-init/jail-vars.sh
            #
            # key for the ingress jail
            #
            sudo jexec $INGRESS_JAIL mkdir /usr/local/etc/ssl
            sudo jexec $INGRESS_JAIL touch /usr/local/etc/ssl/${INGRESS_JAIL_CERT}.key
            sudo jexec $INGRESS_JAIL chmod 440 /usr/local/etc/ssl/${INGRESS_JAIL_CERT}.key
            sudo jexec $INGRESS_JAIL chown root:www /usr/local/etc/ssl/${INGRESS_JAIL_CERT}.key

            # copy the cert key into that file
            sudo jexec $INGRESS_JAIL sudoedit /usr/local/etc/ssl/${INGRESS_JAIL_CERT}.key


     1. For nginx hosts:

            ansible-playbook freshports-website-git.yml --limit=aws-1.freshports-nginx01

            # The following is run on the jail host
            # WEB_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bringing those variables into your shell: . /usr/local/etc/host-init/jail-vars.sh
            #
            # key for the nginx jail
            #
            sudo jexec $WEB_JAIL mkdir /usr/local/etc/ssl
            sudo jexec $WEB_JAIL touch /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chmod 440 /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chown root:www /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # copy the cert key into that file
            sudo jexec $WEB_JAIL sudoedit /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # this will attempt to start nginx, which will fail, because it does
            # not have the certificate yet, but it is all configured to go.
            # that is OK, because it is the last step performed.
            # we could just run cert-puller first.

     1. for the mx-ingress jail

            ansible-playbook freshports-mx-ingress-mailserver.yml --limit=aws-1.freshports-mx-ingress04

            # The following is run on the jail host
            # MX_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bringing those variables into your shell: . /usr/local/etc/host-init/jail-vars.sh
            #
            #
            # key for the mx jail
            #
            sudo jexec $MX_JAIL mkdir /usr/local/etc/ssl
            sudo jexec $MX_JAIL touch /usr/local/etc/ssl/${MX_JAIL_CERT}.key
            sudo jexec $MX_JAIL chmod 440 /usr/local/etc/ssl/${MX_JAIL_CERT}.key
            sudo jexec $MX_JAIL chown root:www /usr/local/etc/ssl/${MX_JAIL_CERT}.key

            # copy the cert key into that file
            sudo jexec $MX_JAIL sudoedit /usr/local/etc/ssl/${MX_JAIL_CERT}.key


1. With the required packages installed, try fetching certs etc:

        # This will configure cert-puller.conf, run `cert-puller -s` to get
        # the sudo permissions, and run `cert-puller`
        # The anvil configuration should be done by Ansible re: roles/freshports-configuration-website/tasks/main.yml
        #
        sudo ./06-install-local-files.sh

1. With the certs downloaded and installed, we can do the final configurations.

        ansible-playbook freshports-configuration-ingress.yml --limit=aws-1.freshports-ingress01

        ansible-playbook freshports-configuration-website.yml --limit=aws-1.freshports-nginx01

1. Now that the jails have been configured, we can mount all the filesystems

        sudo service jail stop
 
        sudoedit /etc/jail.conf
        # uncomment things which say AFTER CONFIG

1.  Start the jails again

        sudo service jail start


1.  Create the ~freshports/cache directories on the webserver

        sudo ./07-post-jail-creation-configuration-nginx.sh


1.  Remember to rotate log files

        # the jails need to be started for this one
        sudo ./08-newsyslog.conf

1.  Clone the required repos
        jexec $INGRESS_JAIL -u ingress git clone https://git.FreeBSD.org/src.git ~ingress/repos/src
        jexec $INGRESS_JAIL -u ingress git clone https://git.FreeBSD.org/doc.git ~ingress/repos/doc

        # from https://news.freshports.org/2020/12/21/moving-to-the-freebsd-git-repo-for-src/
        sudo jexec stagegit-ingress01 sudo -u ingress sh -c 'cat > /var/db/ingress/repos/latest.src < EOF
3cc0c0d66a065554459bd2f9b4f80cc07426464a
EOF

        # from https://news.freshports.org/2020/12/17/moving-devgit-freshports-org-from-github-to-git-freebsd-org/
        sudo jexec stagegit-ingress01 sudo -u ingress sh -c 'cat > /var/db/ingress/repos/latest.doc < EOF
89d0233560e4ba181d73143fc25248b407120e09
EOF

        jexec $INGRESS_JAIL -u freshports svn co https://svn.freebsd.org/ports/head            ~freshports/ports-jail/var/db/repos/PORTS-head
        jexec $INGRESS_JAIL -u freshports svn co https://svn.freebsd.org/ports/branches/2021Q1 ~freshports/ports-jail/var/db/repos/PORTS-2021Q1


This FreshPorts instance should now be running
