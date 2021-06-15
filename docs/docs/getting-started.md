---
layout: default
title: Getting Started
nav_order: 2
---

# Getting started
{: .no_toc }

Here we will install the necessary programs and start a connection to a
(local) Oracle database. For the remainder of the documentation I will presume
that the reader is familiar with (and will use) the command line.

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---


## Setting up the environment

### Programs to install (or add to your PATH)

|Program|Download Site                                              |Remark|
|-------|-------------                                              |------|
|Git    |https://git-scm.com/downloads                              |Usually already installed except on Windows|
|Maven  |https://maven.apache.org/download.cgi                      |Usually already installed except on Windows|
|Perl   |https://www.perl.org/get.html                              |Use Strawberry on Windows|
|SQLcl  |https://www.oracle.com/tools/downloads/sqlcl-downloads.html|Included in SQL Developer|

### Check program versions

|Program|Command to get the version|Minimum version|
|-------|--------------------------|---------------|
|Git    |git --version             |2.0.0          |
|Maven  |mvn --version             |3.3.1          |
|Perl   |perl --version            |5.16.0         |
|SQLcl  |sql -V                    |18.1.0.0       |

### Checking out Oracle Tools

I usually create a dev directory where I put all my development stuff:

```
$ mkdir dev
$ cd dev
```

Clone Oracle Tools:

```
$ git clone https://github.com/paulissoft/oracle-tools.git
```

## Making a connection

The oracle-tools/conf/app directory contains a Maven Project Object Model file,
pom.xml, that uses a profile named test-connection to test the connection.

### Making a connection using TNS

Using the famous user SCOTT with password TIGER on the (local) database ORCL like this:

```
$ mvn -f oracle-tools/conf/app -P test-connection --quiet -Ddb.connect.identifier=ORCL -Ddb.username=SCOTT -Ddb.password=TIGER

```

will give output similar to this:

```
Db Url: jdbc:oracle:thin:@ORCL
Db Username: SCOTT
Driver Name: Oracle JDBC driver
Driver Version: 19.3.0.0.0
Default Row Prefetch Value is: 20
Database Username is: SCOTT

OBJECT_TYPE                     OBJECT_NAME
-----------                     -----------
...
```

Please note that the connect identifier ORCL is an entry in tnsnames.ora. That
file is usually located in a directory pointed to by the environment variable
TNS_ADMIN.

### Making a connection using Easy Connect

This will work too, now without TNS:

```
$ mvn -f oracle-tools/conf/app -P test-connection --quiet -Ddb.host=localhost -Ddb.port=1521 -Ddb.service=ORCL -Ddb.username=SCOTT -Ddb.password=TIGER

```
