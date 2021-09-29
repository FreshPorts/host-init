# Extracting latest commit values from database into repo

This section assumes the loaded database already contains `git` commits. To allow processing of commits, you need to have a starting point.
The starting point for each repo is extracted from the database and stored in the `git` repo.

## The repos

In this section, we get a list of repos from the database.

    $ sudo jexec $PG_JAIL
    $ su -l postgres
    $ psql freshports.org
    psql (13.4)
    Type "help" for help.
    
    freshports.org=# select * from repo;
     id | name  |      description       |   repo_hostname    | path_to_repo | repository | db_root_prefix 
    ----+-------+------------------------+--------------------+--------------+------------+----------------
      1 | ports | The FreeBSD Ports tree | svnweb.freebsd.org | /ports       | subversion | 
      2 | doc   | The FreeBSD doc tree   | svnweb.freebsd.org | /doc         | subversion | 
      3 | src   | The FreeBSD src tree   | svnweb.freebsd.org | /base        | subversion | 
      9 | src   | The FreeBSD src tree   | cgit.freebsd.org   | /src         | git        | /base
      8 | doc   | The FreeBSD doc tree   | cgit.freebsd.org   | /doc         | git        | /doc
      7 | ports | The FreeBSD Ports tree | cgit.freebsd.org   | /ports       | git        | /ports
    (6 rows)

We are only interested in the `git` repos.

## Extract the required commit hashes

One by one, let's get the data we need:

### src

    freshports.org=# select id, message_id, commit_date from commit_log where repo_id = 9 order by commit_date desc limit 1;
       id   |                message_id                |      commit_date       
    --------+------------------------------------------+------------------------
     868445 | 007c2463d6d017ad5321d5cd2bc500e577d22196 | 2021-09-17 23:07:23+00
    (1 row)

### doc

    freshports.org=# select id, message_id, commit_date from commit_log where repo_id = 8 order by commit_date desc limit 1;
       id   |                message_id                |      commit_date       
    --------+------------------------------------------+------------------------
     868228 | 79acd015e3ca9188b9b2342276cd4a6bd45ff6ad | 2021-09-15 18:37:51+00
    (1 row)

### ports

#### head

NOTE the use of sorting by `id` to ensure proper ordering when the `commit_date` values are equal. Sure, this
doesn't work if you process the commits out of date. Also, this is a starting point. Attempts to process same commit
twice will not break the system.

    freshports.org=# select CL.id, CL.message_id, CL.commit_date, SB.branch_name
      from commit_log CL, commit_log_branches CLB, system_branch SB
     where CLB.commit_log_id = CL.id 
       and CLB.branch_id     = SB.id
       and CL.repo_id        = 7
       and SB.branch_name    = 'head'
    order by CL.commit_date DESC , CL.id DESC limit 4;
       id   |                message_id                |      commit_date       | branch_name 
    --------+------------------------------------------+------------------------+-------------
     868450 | 724df9e52627ee6e37f0ec7e0269e91a8f84b846 | 2021-09-18 00:49:13+00 | head
     868449 | f2297d3e29d1ea3d04bf47ede23ab9fcb5e87b78 | 2021-09-18 00:49:12+00 | head
     868448 | ff5485f557eb56cf773b92bdbf64cdc6104dbd6e | 2021-09-18 00:49:12+00 | head
     868447 | dbc5f433f85804a16c00019d2994e98337c0ba3d | 2021-09-18 00:49:12+00 | head
    (4 rows)
    
    freshports.org=# 

#### 2021Q3

    freshports.org=# select CL.id, CL.message_id, CL.commit_date, SB.branch_name
      from commit_log CL, commit_log_branches CLB, system_branch SB
     where CLB.commit_log_id = CL.id 
       and CLB.branch_id     = SB.id
       and CL.repo_id        = 7
       and SB.branch_name    = '2021Q3'
    order by CL.commit_date DESC , CL.id DESC limit 4;
       id   |                message_id                |      commit_date       | branch_name 
    --------+------------------------------------------+------------------------+-------------
     868453 | 864d56077f8d0028d91f69cdc71e7d8bd05cfd47 | 2021-09-18 00:51:57+00 | 2021Q3
     868452 | a1b1b9acaa2bd45afda8d0da4a9ad08e8a483781 | 2021-09-18 00:51:57+00 | 2021Q3
     868451 | df465b54f4cd6f45eb2225f216bc208780094d71 | 2021-09-18 00:51:56+00 | 2021Q3
     868394 | 63c152f423a2e475ee380814fb73a718ed0d0703 | 2021-09-17 17:46:47+00 | 2021Q3
    (4 rows)
    
    freshports.org=# 

#### 2021Q2

    freshports.org=# select CL.id, CL.message_id, CL.commit_date, SB.branch_name
      from commit_log CL, commit_log_branches CLB, system_branch SB
     where CLB.commit_log_id = CL.id 
       and CLB.branch_id     = SB.id
       and CL.repo_id        = 7
       and SB.branch_name    = '2021Q2'
    order by CL.commit_date DESC , CL.id DESC limit 4;
       id   |                message_id                |      commit_date       | branch_name 
    --------+------------------------------------------+------------------------+-------------
     859416 | d1da14bab7a800be62786aeb321b781179ea8b3f | 2021-07-03 10:01:24+00 | 2021Q2
     859415 | bf299f1b74f55645289b5cf199d7272c1fe8bf30 | 2021-06-30 20:12:24+00 | 2021Q2
     859414 | 65b0517571c5ed63a287b6e722708f7f13bf66f0 | 2021-06-30 12:48:48+00 | 2021Q2
     859413 | cb3b365038fcaee997eb9e4006a7e2bfed6e5ab0 | 2021-06-30 08:56:01+00 | 2021Q2
    (4 rows)
    
    freshports.org=# 

We don't go back farther than `2021Q2` because that's when `git` started. This step is concerned only with `git` commits.

### NOTE: above data is incomplete.

The ports information needs a commit from each branch, as [found in the code](https://github.com/FreshPorts/git_proc_commit/blob/master/git-to-freshports/git-delta.sh#L82):

* origin/2021Q2
* origin/2021Q3

## Set values in repos

These commands set the value in the respective repos.

Leave the `PostgreSQL` jail and enter the `ingress` jail.

    $ sudo jexec $INGRESS_JAIL
    root@x8dtu-ingress01:/ # su -l ingress
    $ bash

The following commands are derived from https://news.freshports.org/2021/06/27/putting-the-new-git-delta-sh-into-use-on-devgit-freshports-org/

### src

    [ingress@x8dtu-ingress01 ~]$ cd repos/src
    [ingress@x8dtu-ingress01 ~/repos/src]$ git tag -m "last known commit of " -f freshports/origin/main 007c2463d6d017ad5321d5cd2bc500e577d22196
    [ingress@x8dtu-ingress01 ~/repos/src]$ git rev-parse --verify freshports/origin/main^{}
    007c2463d6d017ad5321d5cd2bc500e577d22196

    ### doc

    [ingress@x8dtu-ingress01 ~/repos/src]$ cd ../doc
    [ingress@x8dtu-ingress01 ~/repos/doc]$ git tag -m "last known commit of " -f freshports/origin/main 79acd015e3ca9188b9b2342276cd4a6bd45ff6ad
    [ingress@x8dtu-ingress01 ~/repos/doc]$ git rev-parse --verify freshports/origin/main^{}
    79acd015e3ca9188b9b2342276cd4a6bd45ff6ad

### ports

#### main

    [ingress@x8dtu-ingress01 ~/repos/doc]$ cd ../ports
    [ingress@x8dtu-ingress01 ~/repos/ports]$ git tag -m "last known commit of " -f freshports/origin/main 724df9e52627ee6e37f0ec7e0269e91a8f84b846
    [ingress@x8dtu-ingress01 ~/repos/ports]$ git rev-parse --verify freshports/origin/main^{}
    724df9e52627ee6e37f0ec7e0269e91a8f84b846

#### 2021Q3

    [ingress@x8dtu-ingress01 ~/repos/ports]$ git tag -m "last known commit of " -f freshports/origin/2021Q3 864d56077f8d0028d91f69cdc71e7d8bd05cfd47
    [ingress@x8dtu-ingress01 ~/repos/ports]$ git rev-parse --verify freshports/origin/2021Q3^{}
    864d56077f8d0028d91f69cdc71e7d8bd05cfd47

#### 2021Q2

    [ingress@x8dtu-ingress01 ~/repos/ports]$ git tag -m "last known commit of " -f freshports/origin/2021Q2 d1da14bab7a800be62786aeb321b781179ea8b3f
    [ingress@x8dtu-ingress01 ~/repos/ports]$ git rev-parse --verify freshports/origin/2021Q2^{}
    d1da14bab7a800be62786aeb321b781179ea8b3f

# Ready to go

Now we should be ready to start processing commits.
