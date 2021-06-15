---
layout: default
title: Configuration
nav_order: 3
---

# Configuration
{: .no_toc }


This chapter describes the configuration you can define for Oracle Tools.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---



## Database configuration directory

In oracle-tools there is a directory conf/src that contains the database configuration:

```
|   env.properties
|   flyway-app.conf
|
\---orcl
        apex.properties
        db.properties
        flyway-db.conf
```

The property db.config.dir in Oracle Tools points to this directory.

### env.properties

It currently just contains the name of the the Oracle Tools schema:

```
oracle_tools_schema=ORACLE_TOOLS
```

### flyway-app.conf

Properties defined here are global (i.e. for every database). It now contains:

```
flyway.placeholders.apex.application=${apex.application}
```

This means that you can use ${apex.application} in a migration script that
may be run by Flyway, see [Placeholders](https://flywaydb.org/documentation/configuration/placeholder).

### orcl

The directory for the local database ORCL.

#### orcl/apex.properties

```
workspace=DEV_WKS
```

#### orcl/db.properties

The standard properties for a locally installed database:

```
host=localhost
port=1521
service=orcl
```

#### orcl/flyway-db.conf


This now contains:

```
flyway.placeholders.oracle_tools_schema=${oracle_tools_schema}
flyway.placeholders.oracle_wallet_path=
```

This allows you to have a different Oracle Tools schema or Oracle wallet on every database.

### Oracle Connections

#### Easy Connect

See [How to connect to Oracle Autonomous Cloud
Databases](https://blogs.oracle.com/opal/how-connect-to-oracle-autonomous-cloud-databases)
for a nice introduction on how to connect to the Oracle Autonomous Cloud Database.

#### Good old TNS

The best way to handle connections using TNS is:
1. to define an environment variable TNS_ADMIN pointing to the directory where
tnsnames.ora and sqlnet.ora are located;
2. define the connections in tnsnames.ora.

In the latter case: if there is a (Cloud) wallet involved, unzip it in a
dedicated directory and copy the relevant entries from that tnsnames.ora to
your $TNS_ADMIN/tnsnames.ora. But you must not forget to add
my_wallet_directory like this:

```
db_tst =
  (description= (retry_count=20)(retry_delay=3)
	  (address=(protocol=tcps)(port=1522)(host=ABCDEF.oraclecloud.com))
		(connect_data=
		  (service_name=dbABCDEF_high.adwc.oraclecloud.com)
		)
		(security=
		  (my_wallet_directory=c:\dev\wallet\TST)
		  (ssl_server_cert_dn="CN=ABCDEF.oraclecloud.com,OU=Oracle somewhere,O=Oracle Corporation,L=Redwood City,ST=California,C=US")
		)
	)
```

The original entry was dbABCDEF_high but I just renamed it into something more
convenient.

Now the database configuration directory could contain a subdirectory named
`db_tst` with these db.properties:

```
connect.identifier=db_tst
```

So no more hassles with host, port and service name. But everywhere the Oracle
Tool is used, these TNS entries have to be in the tnsnames.ora.

## Properties used

This is a list of the Maven properties used by Oracle Tools along with their
defaults:

### oracle-tools/conf/pom.xml

|Property             |Default                                               |Description                                                              |
|--------             |-------                                               |-----------                                                              |
|db.schema            |${project.artifactId}                                 |Defaults to POM artifactId assuming it is named after the database schema|
|db.password          |${env.DB_PASSWORD}                                    |Defaults to environment variable DB_PASSWORD                             |
|db.config.dir        |directory of **/conf/env.properties                   |Database configuration directory                                         |
|db                   |                                                      |One of the subdirectories of ${db.config.dir}                            |
|db.connect.identifier|//${db.host}:${db.port}/${db.service}                 |Part of the database URL                                                 |
|db.url               |jdbc:oracle:thin:@${db.connect.identifier}            |JDBC database URL                                                        |
|db.userid            |${db.username}/${db.password}@${db.connect.identifier}|SQLcl connect string                                                     |


