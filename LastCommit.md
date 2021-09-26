# Extracting latest commit values from database into repo

This section assumes the loaded database already contains `git` commits. To allow processing of commits, you need to have a starting point.
The starting point for each repo is extracted from the database and stored in the `git` repo.

## The repos

In this section, we get a list of repos from the database.

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

    freshports.org=# select id, message_id, commit_date from commit_log where repo_id = 7 order by commit_date desc limit 1;
       id   |                message_id                |      commit_date       
    --------+------------------------------------------+------------------------
     868452 | a1b1b9acaa2bd45afda8d0da4a9ad08e8a483781 | 2021-09-18 00:51:57+00
    (1 row)

## Set values in repos

These commands set the value in the respective repos.


TO BE CONTINUED
