# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail), now a [FreeBSD port](https://www.freshports.org/sysutils/mkjail/).

## Before running the scripts

* add the A and PTR records for the new hosts
* add the grant permissions for TXT records for Let's Encrypt (if you're going to issue certs for the website)
* create the website cert
  * if your hostname will be `dvl.freshports.org`, you'll probably have two jails:
    * dvl-ingress01
    * dvl-nginx01 (note the certificate file needs to have the same name as the jail + whatever hostname is used to get to that website - e.g `dvl.freshports.org`)
    * e.g. [acme@certs ~]$ acme.sh --issue --force --dns dns_nsupdate -d dvl-ingress01.int.unixathome.org -d dvl.freshports.org -k 4096 --server letsencrypt 
  * name them after the host which will be used to access this FreshPorts host
* Follow the [Ansible.md](Ansible.md) instructions to prepare the hosts

## The scripts

These are the scripts to run after the above.

1. Configure the host itself by running this Ansible script. This will
install the prerequisite packages such as git, unbound, ntpd, etc.

        ansible-playbook freshports-host.yml --limit=x8dtu-freshports.org

1. Get the `host-init` scripts
    
        mkdir ~/src
        cd ~/src
        git clone https://github.com/FreshPorts/host-init
        cd host-init
        sudo mkdir -p /usr/local/etc/host-init
        sudo cp -i jail-vars.sh.sample /usr/local/etc/host-init/jail-vars.sh
        # adjust the ZPOOL and JAILROOT to your requirements in jail-vars.sh - also set values for the _CERT variables


1. Configure `mkjail.conf`:

        # adjust the ZPOOL, JAILDATASET, and VERSION to your requirements
        sudoedit  /usr/local/etc/mkjail.conf

1. Start running the configuration scripts

        cd ~/src/host-init (or wherever you checked it out)

        sudo ./01-jail-fileset-initialize.sh

        # start stuff on the host which are needed by the jails
        # eg. unbound
        sudo ./02-start-required-services

1. Create the jails

        # This creates the jails which will be later configured by Ansible
        sudo ./03-create-jails.sh

        # Take the jails you're using, and copy them over
        # you might also have to add this to /etc/rc.conf
        # jail_enable="YES"
        # jail_reverse_stop="YES"
        # jail_list="jail-ingressjail-nginx jail-pg"
        # jail_sysvipc_allow="YES" # For PostgreSQL
        #
        sudo cp -i jail-ingress.conf jail-nginx.conf jail-pg.conf /etc/jail.conf.d/

1. Start the jails

        sudo service jail start

1. Configure the jails for running Ansible

        sudo ./05-prepare-jails-for-ansible.sh

        # if you haven't already, do the Ansible configuration outlined in
        # Ansible.md

1. Switch over to the ansible host and run some or all of these commands

     1. For postgresql hosts:

            # The following is run on the jail host
            # PG_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bring those variables into your shell: 
            
            . /usr/local/etc/host-init/jail-vars.sh
            
            # copy the cert key into that file
            sudo jexec $PG_JAIL sudoedit /usr/local/etc/ssl/${PG_JAIL_CERT}.key

            ansible-playbook jail-postgresql.yml --limit=x8dtu-freshports-pg01

            # that may end with:
            #
            # fatal: [x8dtu-freshports-pg01]: FAILED! => {"changed": false, "msg": "pg_ctl: could not start server\nExamine the log output.\n"}
            #
            # if so, go ahead with the next step. 06-install-local-files.sh should fix that
            #


     1. For ingress hosts:

            # The following is run on the jail host

            ansible-playbook freshports-ingress.yml --limit=x8dtu-freshports-ingress01

     1. For nginx hosts:

            # The following is run on the jail host
            # WEB_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bringing those variables into your shell:
            
            . /usr/local/etc/host-init/jail-vars.sh
            
            #
            # key for the nginx jail
            #
            sudo jexec $WEB_JAIL mkdir -p /usr/local/etc/ssl
            sudo jexec $WEB_JAIL touch /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chmod 440 /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chown root:www /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # copy the cert key into that file
            sudo jexec $WEB_JAIL sudoedit /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # adjust `/etc/jail.conf.d/jail-nginx` and enable the ZFS filesystems
            ansible-playbook freshports-website.yml --limit=x8dtu-freshports-nginx01

1. With the required packages installed, try fetching certs etc:

        # This will configure cert-puller.conf, run `cert-puller -s` to get
        # the sudo permissions, and run `cert-puller`
        # The anvil configuration should be done by Ansible re: roles/freshports-configuration-website/tasks/main.yml
        #
        sudo ./06-install-local-files.sh

1. With the certs downloaded and installed, we can do the final configurations.

        ansible-playbook freshports-configuration-ingress.yml --limit=x8dtu-freshports-ingress01

        ansible-playbook freshports-configuration-website.yml --limit=x8dtu-freshports-nginx01

1. Now that the jails have been configured, we can mount all the filesystems

        sudo service jail stop
 
        sudoedit /etc/jail.conf.d/jail-*.conf
        # uncomment things which say commented out until after step 10

1.  Start the jails again

        sudo service jail start (or just specify the jails you want to stop)


1.  Create the ~freshports/cache directories on the webserver

        sudo ./07-post-jail-creation-configuration-nginx.sh


1.  Remember to rotate log files

        # the jails need to be started for this one
        sudo ./08-newsyslog.conf

1.  Uncomment the remaining items in `/etc/jail.conf`. Look for `commented out until after step 13`:


        # NOTE: last time I did this, there were no such items.
        sudo service jail stop
        sudoedit /etc/jail.conf
        sudo service jail start

1.  Configure the freshports jail within the ingress jail:

        sudo ./10-configure-jail-in-ingress-jail.sh

1.  Add snmpd credentials for snmpd in the PostgreSQL and Nginx jails:

        # https://dan.langille.org/2021/04/03/net-mgmt-net-snmpd-wants-snmp-snmpd-conf/
        sudo jexec $JAIL
        mkdir /snmp

        # https://dan.langille.org/2015/09/07/installing-net-mgmtnet-snmpd-and-getting-it-running/
        service snmpd stop
        net-snmp-config --create-snmpv3-user -ro -x AES -a SHA -A 'supersecretauth' -X supersecretXX someone
        service snmpd start

        # then add this host to LibreNMS
        
1.  Special file systems for FreshPorts

    #### ingress node

    * `/var/db/ingress/repos`       (about 10 GB)
    * `/jails/freshports/usr/ports` (about 50 GB)

    For creation:

    #### ingress node

    	sudo zfs create -o canmount=off                                                 ${datazpool}/freshports
    	sudo zfs create -o canmount=off                                                 ${datazpool}/freshports/${INGRESS_JAIL}
    	sudo zfs create -o mountpoint=/jails/${INGRESS_JAIL}/var/db/ingress/repos       ${datazpool}/freshports/${INGRESS_JAIL}/repos
    	sudo zfs create -o                                                              ${datazpool}/freshports/${INGRESS_JAIL}/repos/docs
    	sudo zfs create -o                                                              ${datazpool}/freshports/${INGRESS_JAIL}/repos/ports
    	sudo zfs create -o                                                              ${datazpool}/freshports/${INGRESS_JAIL}/repos/src
    	sudo zfs create -o mountpoint=/jails/${INGRESS_JAIL}/jails/freshports/usr/ports ${datazpool}/freshports/${INGRESS_JAIL}/ports

        # these need non root:wheel permissions
        # this needs to be done after the ingress user is created
        sudo jexec ${INGRESS_JAIL} chown -R ingress:ingress /var/db/ingress/repos

    #### Useful at times, not part of the setup.

   This section shows how to umount what we just created, check the underlying directories, then mount.

        sudo zfs umount ${datazpool}/freshports/${INGRESS_JAIL}/ports
        sudo zfs umount ${datazpool}/freshports/${INGRESS_JAIL}/repos

        # just to be sure we're not overlaying something unintenionally
        ls -l /jails/${INGRESS_JAIL}/var/db/ingress/repos /jails/${INGRESS_JAIL}/jails/freshports/usr/ports

        sudo zfs  mount ${datazpool}/freshports/${INGRESS_JAIL}/ports
        sudo zfs  mount ${datazpool}/freshports/${INGRESS_JAIL}/repos

    #### postgresql node

        # before you create this, you'll want to move the old one away
        sudo jexec ${PG_JAIL} service postgresql stop
        sudo mv /jails/${PG_JAIL}/var/db/postgres /jails/${PG_JAIL}/var/db/postgres.old

        # this needs to be done after postgresql server is installed but before the initdb
        # that may be tricky because 
        sudo zfs create -o canmount=off                                 ${datazpool}/freshports/${PG_JAIL}
        sudo zfs create -o mountpoint=/jails/${PG_JAIL}/var/db/postgres ${datazpool}/freshports/${PG_JAIL}/postgres
        sudo jexec ${PG_JAIL} chown postgres:postgres /var/db/postgres
        
        sudo mv /jails/${PG_JAIL}/var/db/postgres.old/* /jails/${PG_JAIL}/var/db/postgres
        sudo jexec ${PG_JAIL} service postgresql start


1.  Create the database

        # the roles and users need to be created first
        # run this ansible script for the ingress host in question
        ansible-playbook freshports-database-passwords.yml --limit=x8dtu-freshports-ingress01

        # This will create a file on the ingress host at /root/freshports-roles.sql
        # copy it to the PG jail

        sudo cp -i /jails/$INGRESS_JAIL/root/freshports-roles.sql /jails/$PG_JAIL/var/db/postgres
        sudo jexec $PG_JAIL chown postgres:postgres /var/db/postgres/freshports-roles.sql

        sudo jexec ${PG_JAIL}
        pkg install databases/postgresql13-plperl
        su -l postgres
        createdb -T template0 -E SQL_ASCII freshports.org

        psql
        begin;
        \i freshports-roles.sql

        # if all good:
        commit;

        # otherise:
        rollback;

        # set the -j parameter to the number of CPUs on this host
        # Timing is not required. I just like it.
        time pg_restore -j 16 -d freshports.org freshports.org.dump


1.  Clone the required `git` repos for the `ingress` user:

        sudo jexec $INGRESS_JAIL
        su -l ingress
        git clone https://git.FreeBSD.org/src.git   ~ingress/repos/src
        git clone https://git.FreeBSD.org/doc.git   ~ingress/repos/doc
        git clone https://git.FreeBSD.org/ports.git ~ingress/repos/ports



1.  Get a copy of the git ports repo for the `freshports` jail. This can be owned by `root`, all operations are performed as root from within the jail.

        sudo jexec $INGRESS_JAIL
        git clone https://git.FreeBSD.org/ports.git /jails/freshports/usr/ports


This FreshPorts instance should now be running - but no commit processing is occuring. Next, 
you'll need to [extract and set repo starting points](LastCommit.md). Later, you'll need to enable
various periodic scripts and daemons.

# code checkouts for a development host:

## INGRESS

NOTE: This needs to be done before the ansible scripts install
the freshports-freshports package - which means this section needs to move up
in this file.

	sudo mkdir /usr/local/lib/perl5/site_perl/FreshPorts
	sudo chown -R dvl:dvl /usr/local/lib/perl5/site_perl/FreshPorts
	ln -s /usr/local/lib/perl5/site_perl/FreshPorts ~/modules

	cd ~/modules
	svn co svn+ssh://svnusers@svn.int.unixathome.org/freshports-1/ingress/modules/branches/git .

	sudo mkdir /usr/local/libexec/freshports
	sudo chown -R dvl:dvl /usr/local/libexec/freshports
	ln -s /usr/local/libexec/freshports ~/scripts

	cd ~/scripts
	svn co svn+ssh://svnusers@svn.int.unixathome.org/freshports-1/ingress/scripts/branches/git .

	mkdir ~/src/
	cd ~/src
	svn co svn+ssh://svnusers@svn.int.unixathome.org/freshports-1/packaging/trunk packaging

	cd packaging
	see README.txt - run the commands therein - it registers fake packages to
	avoid having your code overwritten by the real packages.

### symlinks you'll need
	cd ~/modules
	sudo ln -s /usr/local/etc/freshports/config.pm .
	sudo ln -s /usr/local/etc/freshports/status.pm .

	cd ~/scripts
	sudo ln -s /usr/local/etc/freshports/config.sh .

### jail configuration

This configures the jail for extracting port information

	cd ~/scripts/Jail/scripts
	sudo ./copy-scripts-into-jail.sh /jails/freshports
	cd /jails/freshports
	sudo cp -i vars.sh.sample vars.sh


## WWW

	sudo mkdir /usr/local/www/freshports
	sudo chown dvl:dvl /usr/local/www/freshports
	ln -s /usr/local/www/freshports ~/www
	cd ~/www
	git clone git@github.com:FreshPorts/freshports.git .

	mkdir ~/src/
	cd ~/src
	svn co svn+ssh://svnusers@svn.int.unixathome.org/freshports-1/packaging/trunk packaging

	cd packaging
	see README.txt - run the commands therein - it registers fake packages to
	avoid having your code overwritten by the real packages.

### website configuration

	cd /usr/local/www/freshports/configuration
	sudo cp -i vhosts.conf.nginx.sample vhosts.conf.nginx
	sudo cp -i virtualhost-common.conf.sample     /usr/local/etc/freshports/virtualhost-common.conf
	sudo cp -i virtualhost-common-ssl.conf.sample /usr/local/etc/freshports/virtualhost-common-ssl.conf
	sudo cp -i freshports.conf.php.sample         /usr/local/etc/freshports/freshports.conf.php

	cd /usr/local/www/freshports/include
	sudo cp -i common.php.sample          /usr/local/etc/freshports/common.php
	sudo cp -i constants.local.php.sample /usr/local/etc/freshports/constants.local.php
