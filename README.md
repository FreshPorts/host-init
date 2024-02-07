# FreshPorts host configuration

This directory contains scripts to get a FreshPorts system off the ground.

It uses [mkjail](https://github.com/mkjail/mkjail), now a [FreeBSD port](https://www.freshports.org/sysutils/mkjail/).

## Before running the scripts

* add the A and PTR records for the new hosts
* add the grant permissions for TXT records for Let's Encrypt (if you're going to issue certs for the website)
* create the website cert
  ** if your hostname will be `dvl.freshports.org`, you'll probably have two jails:
  *** dvl-ingress01
  *** dvl-nginx01 (this one needs a cert for `dvl.freshports.org`)
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
        sudo mkdir /usr/local/etc/host-init
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

        sudo cp -i jail.conf /etc/jail.conf

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

            ansible-playbook freshports-ingress-git.yml --limit=x8dtu-freshports-ingress01

     1. For nginx hosts:

            # The following is run on the jail host
            # WEB_JAIL_CERT is defined in /usr/local/etc/host-init/jail-vars.sh
            # bringing those variables into your shell:
            
            . /usr/local/etc/host-init/jail-vars.sh
            
            #
            # key for the nginx jail
            #
            sudo jexec $WEB_JAIL mkdir /usr/local/etc/ssl
            sudo jexec $WEB_JAIL touch /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chmod 440 /usr/local/etc/ssl/${WEB_JAIL_CERT}.key
            sudo jexec $WEB_JAIL chown root:www /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # copy the cert key into that file
            sudo jexec $WEB_JAIL sudoedit /usr/local/etc/ssl/${WEB_JAIL_CERT}.key

            # adjust `/etc/jail.conf` and enable the ZFS filesystems
            ansible-playbook freshports-website-git.yml --limit=x8dtu-freshports-nginx01

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
 
        sudoedit /etc/jail.conf
        # uncomment things which say commented out until after step 10

1.  Start the jails again

        sudo service jail start


1.  Create the ~freshports/cache directories on the webserver

        sudo ./07-post-jail-creation-configuration-nginx.sh


1.  Remember to rotate log files

        # the jails need to be started for this one
        sudo ./08-newsyslog.conf

1.  Uncomment the remaining items in `/etc/jail.conf`. Look for `commented out until after step 13`:

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

    ingress node

    * `/var/db/ingress/repos`       (about 10 GB)
    * `/jails/freshports/usr/ports` (about 50 GB)

    For creation:

        sudo zfs create -o canmount=off                                                 zroot/freshports
        sudo zfs create -o canmount=off                                                 zroot/freshports/ingress01
        sudo zfs create -o mountpoint=/jails/${INGRESS_JAIL}/var/db/ingress/repos       zroot/freshports/ingress01/repos
        sudo zfs create -o mountpoint=/jails/${INGRESS_JAIL}/jails/freshports/usr/ports zroot/freshports/ingress01/ports

        # these need non root:wheel permissions
        # this needs to be done after the ingress user is created
        jexec ${INGRESS_JAIL} chown ingress:ingress /var/db/ingress/repos


        # before you create this, you'll want to move the old one away
        sudo jexec ${PG_JAIL} service postgresql stop
        sudo mv /jails/${PG_JAIL}/var/db/postgres /jails/${PG_JAIL}/var/db/postgres.old

        # this needs to be done after postgresql server is installed but before the initdb
        # that may be tricky because 
        sudo zfs create -o canmount=off                                 zroot/freshports/${PG_JAIL}
        sudo zfs create -o mountpoint=/jails/${PG_JAIL}/var/db/postgres zroot/freshports/${PG_JAIL}/postgres
        sudo jexec ${PG_JAIL} chown postgres:postgres /var/db/postgres
        
        sudo mv /jails/${PG_JAIL}/var/db/postgres.old/* /jails/${PG_JAIL}/var/db/postgres
        sudo jexec ${PG_JAIL} service postgresql start

    Useful at times, not part of the setup.

        sudo zfs umount zroot/freshports/${INGRESS_JAIL}/ports
        sudo zfs umount zroot/freshports/${INGRESS_JAIL}/repos

        # just to be sure we're not overlaing something unintenionally
        ls -l /jails/${INGRESS_JAIL}/var/db/ingress/repos /jails/${INGRESS_JAIL}/jails/freshports/usr/ports

        sudo zfs  mount zroot/freshports/${INGRESS_JAIL}/ports
        sudo zfs  mount zroot/freshports/${INGRESS_JAIL}/repos

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



1.  Get a copy of the git ports repo for the `freshports` jail:

        jexec $INGRESS_JAIL
        git clone https://git.FreeBSD.org/ports.git /jails/freshports/usr/ports


This FreshPorts instance should now be running - but no commit processing is occuring. Next, 
you'll need to [extract and set repo starting points](LastCommit.md). Later, you'll need to enable
various periodic scripts and daemons.
