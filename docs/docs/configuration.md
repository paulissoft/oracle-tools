---
layout: default
title: Configuration
nav_order: 4
---

# Configuration
{: .no_toc }


This chapter describes the configuration you can define for PATO.
{: .fs-6 .fw-300 }

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Profiles

Before we dive into the configuration it is important to note that Maven profiles are available to execute the following actions.

Of course it is possible to work without Maven profiles but why should you?

### Database

|Profile (action)    |Description|
|:---------------    |:----------|
|db-info             |Show Flyway information about (to be) installed migrations.|
|db-install          |Perform Flyway migrations.|
|db-code-check       |Use native PL/SQL code checks based on PL/SQL warnings and PL/Scope.|
|db-test             |Execute a unit test using utPLSQL v3.|
|db-generate-ddl-full|Generate DDL scripts assuming that there are no objects yet.|
|db-generate-ddl-incr|Generate DDL scripts to migrate non repeatable objects that may already be there.|

### Apex

|Profile (action)    |Description|
|:---------------    |:----------|
|apex-export         |Export an Apex application.|
|apex-import         |Import an Apex application.|

## Configuration files directory

In oracle-tools there is a directory conf/src that contains the configuration files:

```
|   env.properties
|   flyway-app.conf
|
\---orcl
        apex.properties
        db.properties
        flyway-db.conf
```

Here orcl is the logical name for a database.

The property db.config.dir in PATO by default points to the directory conf/src.

However you can set db.config.dir to another directory anywhere provided you
have a file called env.properties there and other database directories below.

### env.properties

It currently just contains the name of the PATO schema:

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

This allows you to have a different PATO schema or Oracle wallet on every database.

## Oracle Connections

### Easy Connect

See [How to connect to Oracle Autonomous Cloud
Databases](https://blogs.oracle.com/opal/how-connect-to-oracle-autonomous-cloud-databases)
for a nice introduction on how to connect to the Oracle Autonomous Cloud Database.

### Good old TNS

The best way to handle connections using TNS is to:
1. define an environment variable TNS_ADMIN pointing to the directory where
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
Tool is used, this TNS entry has to be in the tnsnames.ora.

## Properties used

This is a list of the Maven properties used by PATO along with their
defaults:

### oracle-tools/conf/pom.xml

This is the POM that can be used as parent for projects that need a database connection.

|Property             |Default                                               |Description                                                               |
|:-------             |:------                                               |:----------                                                               |
|db.schema            |${project.artifactId}                                 |Defaults to POM artifactId assuming it is named after the database schema.|
|db.password          |${env.DB_PASSWORD}                                    |Defaults to environment variable DB_PASSWORD.                             |
|db.config.dir        |directory of **/conf/env.properties                   |Database configuration directory.                                         |
|db                   |                                                      |One of the subdirectories of ${db.config.dir}.                            |
|db.connect.identifier|//${db.host}:${db.port}/${db.service}                 |Part of the database URL.                                                 |
|db.url               |jdbc:oracle:thin:@${db.connect.identifier}            |JDBC database URL.                                                        |
|db.userid            |${db.username}/${db.password}@${db.connect.identifier}|SQLcl connect string.                                                     |

### oracle-tools/db/pom.xml

This is the POM that can be used as parent for projects that issue database
actions. It has oracle-tools/conf/pom.xml as its parent POM.

#### Flyway related properties

For profiles (actions) db-info and db-install:

|Property                |Default                             |Description                                                              |
|:-------                |:------                             |:----------                                                              |
|db.src.scripts          |src                                 |The root directory for Flyway migration scripts.                         |
|db.src.dml.scripts      |${db.src.scripts}/dml               |The directory containing DML scripts.                                    |
|db.src.full.scripts     |${db.src.scripts}/full              |The directory containing DDL scripts that can be run over and over again.|
|db.src.incr.scripts     |${db.src.scripts}/incr              |The directory containing DDL scripts that can be run only once.          |
|db.src.callbacks.scripts|${oracle-tools.db.src.dir}/callbacks|The directory that contains scripts run before or after Flyway.          |

#### Properties for code checks and generating DDL

For profiles (actions) db-code-check, db-generate-ddl-full and db-generate-ddl-incr the following properties are common:

|Property                            |Default|Description                                                                                  |
|:-------                            |:------|:----------                                                                                  |
|db.object.type                      |       |Only generate for this object type (see Oracle package DBMS_METADATA for possible values).   |
|db.object.names                     |       |A list of object names to include or exclude (or empty to include all).                      |
|db.object.names.include             |       |Specifies what to do with db.object.names: empty (no filter), 0 (exclude) or 1 (include).    |

##### Profile db-code-check

|Property                            |Default                      |Description|
|:-------                            |:------                      |:----------|
|db.recompile                        |1                            |Must the code checker recompile objects to have a detailed analysis: yes (1) or no (0)? Probably not in production!|
|db.plsql.warnings                   |ENABLE:ALL                   |For "alter session set PLSQL_WARNINGS = '${db.plsql.warnings}'".|
|db.plscope.settings                 |IDENTIFIERS:ALL              |For "alter session set PLSCOPE_SETTINGS = '${db.plscope.settings}'".|

Please note that these properties are defined in oracle-tools/conf/pom.xml but
only when they have not been defined before. So you can for example add this line

```
recompile=0
```

to a production db.properties file (prefix db. is added by default for such a
file) to ensure that by default no recompilation takes place in production
when you invoke db-code-check.

##### Profile db-generate-ddl-full

|Property                            |Default                      |Description|
|:-------                            |:------                      |:----------|
|db.full.remove.output.directory     |yes                          |Remove the output directory (${db.src.full.scripts}) before generating DDL scripts?|
|db.full.force.view                  |no                           |CREATE OR REPLACE **FORCE** VIEW or not?|
|db.full.group.constraints           |yes                          |Referential constraints per base object will be grouped in one file (just like the other constraints) in order to create them at the end.|
|db.full.skip.install.sql            |yes                          |skip creating install.sql/uninstall.sql scripts?|
|db.full.interface                   |pkg_ddl_util v5              |Interface version for creating DDL scripts. Script naming convention is &lt;PREFIX&gt;&lt;SEQ&gt;.&lt;OWNER&gt;.&lt;TYPE&gt;.&lt;NAME&gt;.sql where PREFIX is "R__" for replaceable objects and empty otherwise, sequence number SEQ depends on TYPE for "pkg_ddl_util v4" and the place in file install_sequence.txt for "pkg_ddl_util v5".|
|db.full.transform.params            |SEGMENT_ATTRIBUTES,TABLESPACE|A comma separated list of SEGMENT_ATTRIBUTES, STORAGE, TABLESPACE (all table related) and OID (needed for object types used with database links).|
|db.generate.ddl.full.skip           |                             |Skip generating full DDL scripts for this project? False when ${db.src.full.scripts} exists.|
|db.generate.full.strip.source.schema|0                            |Strip source schema from 'create or replace "source schema"."source name"': yes (1) or no (0).|

##### Profile db-generate-ddl-incr

|Property                            |Default                      |Description                                                                                 |
|:-------                            |:------                      |:----------                                                                                 |
|db.incr.dynamic.sql                 |no                           |Use dynamic SQL for the incremental migration scripts?                                      |
|db.incr.skip.repeatables            |yes                          |Skip repeatable/replaceable objects in incremental migration scripts?                       |
|db.incr.interface                   |pkg_ddl_util v5              |See description for db.full.interface above.                                                |
|db.incr.transform.params            |SEGMENT_ATTRIBUTES,TABLESPACE|See description for db.full.transform.params above.                                         |
|db.generate.ddl.incr.skip           |                             |Skip generating full DDL scripts for this project? False when ${db.src.full.scripts} exists.|

#### Properties for running utPLSQL

The profile (action) is db-test:

|Property       |Default                           |Description                                                                   |
|:-------       |:------                           |:----------                                                                   |
|db.utplsql.path|${db.schema}:${project.artifactId}|Run utPLSQL for packages with utPLSQL suitepath equal to their POM artifactId.|
|db.test.phase  |none                              |Set this to test in your project POM in order to activate it.                 |

### oracle-tools/apex/pom.xml

This is the POM that can be used as parent for projects that issue Apex 
actions. It has oracle-tools/conf/pom.xml as its parent POM.

For profiles (actions) apex-export and apex-import:

|Property                |Default               |Description                                                               |
|:-------                |:------               |:----------                                                               |
|apex.src.dir            |${basedir}/src        |The project source directory.                                             |
|apex.application.dir    |${apex.src.dir}/export|The Apex export directory with splitted SQL scripts.                      |
|apex.workspace          |                      |The Apex workspace.                                                       |
|apex.application        |                      |The Apex application id.                                                  |
|apex.application.version|current date/time     |In Java yyyy-MM-dd hh:mm:ss format, used in Apex application version info.|
|sql.home                |                      |The home directory of SQLcl (${sql.home}/bin/sql exists?).                |
|env.SQL_HOME            |                      |Idem but now the environment variable SQL_HOME.                           |
