# PATO (Paulissoft Application Tools for Oracle)

If you are interested in the ideas behind this project and more in-depth knowledge about PATO, you may want to buy my e-book ["How to Build an Oracle Database Application", Leanpub](https://leanpub.com/build-oracle-apex-application).

![Quick but not dirty](https://d2sofvawe08yqg.cloudfront.net/build-oracle-apex-application/s_hero?1680348922)

This project contains:
- Maven build software for deploying Oracle software (database and Apex).
- Apex and database tools installed by the build software.

## Maven build

See the various POM files. 

There is also [a Python GUI for PATO as an alternative for the Maven command line](https://github.com/paulissoft/pato-gui).

And finally for CI/CD purposes there is a Jenkins CI/CD setup in the `jenkins` folder, but please read the book for more information.

## Tools

A set of application tools for Oracle developers.

Currently it includes:
- a PL/SQL DDL generator (that can be used to describe your deployment).
- an Apex application to load spreadsheet files into a database table/view.
- a table partition package to make it easy to drop (and backup) old partitions.
- ADMIN packages to kill sessions and stop jobs.
- a Do It Yourself message subsystem as a replacement for Oracle Query Notification.
- a heartbeat mechanism for keeping related processes (jobs) alive or shut them down gracefully.
- various PL/SQL utilities to help with development.

### PL/SQL DDL generator

See the folder `db/app/ddl`.

### Apex application to load spreadsheet files

The following MIME spreadsheet types (with extension between parentheses) are supported:
- application/vnd.openxmlformats-officedocument.spreadsheetml.sheet (.xlsx)
- application/vnd.ms-excel (.xls)
- application/vnd.ms-excel.sheet.binary.macroEnabled.12 (.xlsb)
- application/vnd.oasis.opendocument.spreadsheet (.ods)

This project depends on the [ExcelTable GitHub project](https://github.com/mbleron/ExcelTable.git).

See also the folder `db/app/ext` for the back-end part.

### Table partition package

See the files for package `DATA_PARTITIONING_PKG` in folder `db/app/data/src/full`.

### ADMIN packages to kill sessions and stop jobs

When a job session is blocking due to `DBMS_AQ.listen` or similar calls, it is not sufficient to stop the jobs using `DBMS_SCHEDULER.stop_job` since the slave session process may keep on running somehow. The packages `ADMIN_SYSTEM_PKG` and `ADMIN_SCHEDULER_PKG` will really stop the job and kill the session (only for the session user).

See folder `db/app/admin/src/full`.
 
### Do It Yourself message subsystem

A Object Oriented based message subsystem where you can either decide to process a message now (synchronous) or later (asynchronous). It uses Oracle Advanced Queuing and Oracle Scheduler jobs to achieve this.

Oracle Query Notification was deemed to be too limited (only PL/SQL notifications, registration difficult, etcetera).

See the files in folder `db/app/msg/src/full`.

### Heartbeat mechanism

The message subsystem has supervisor and worker jobs that listen on the various queues. In order to gracefully shut them down and to keep them running when one process is accidently stopped or killed, this heartbeat mechanism based on `DBMS_PIPE` has been built.

See the files for package `API_HEARTBEAT_PKG` in folder `db/app/api/src/full`.

### Various PL/SQL utilities

Utilities to enable/disable constraints, manage Apex messages and so on.

See the sub folders in `db/app`.

## Installation of all the tools

The installation of an Oracle database and Oracle APEX is out of scope.

### Setting up the database schema(s)

Creating the database schema(s) for the ExcelTable and tools software is out of scope.

The proposed database schema for installing PATO is ORACLE_TOOLS.

### Installing ExcelTable

See the [ExcelTable README](https://github.com/mbleron/ExcelTable) for further instructions.

When the PATO database schema differs from this ExcelTable schema then you must grant privileges like this:

```
SQL> grant execute on ExcelTable to <PATO database schema>;
```

### Installing PATO from source

First clone the project:

```
$ git clone https://github.com/paulissoft/oracle-tools.git
```

#### Installing the database software

```
$ cd oracle-tools/tools/db
$ mvn -Pdb-install -Ddb=<db from oracle-tools/conf/src> -Ddb.schema=<username> -Ddb.password=<password>
```

#### Installing the APEX application

```
$ cd oracle-tools/tools/apex
$ mvn -Papex-import -Ddb=<db from oracle-tools/conf/src> -Ddb.schema=<username> -Ddb.password=<password>
```

## Using PATO in other Maven projects

### Using PATO on the file system on the same level as your project

This is an example file layout:


```
.../projects/oracle-tools
.../projects/YOUR-PROJECT
```

#### Database POM

The .../projects/YOUR-PROJECT/db/pom.xml may have as parent:

```
<parent>
  <groupId>com.paulissoft.oracle-tools</groupId>
  <artifactId>db</artifactId>
  <version>${revision}</version>
  <relativePath>../../oracle-tools/db</relativePath>
</parent>
```

#### Apex POM

The .../projects/YOUR-PROJECT/apex/pom.xml may have as parent:

```
<parent>
  <groupId>com.paulissoft.oracle-tools</groupId>
  <artifactId>apex</artifactId>
  <version>${revision}</version>
  <relativePath>../../oracle-tools/apex</relativePath>
</parent>
```

### Using Maven dependencies

This is deprecated since it is too fragile. see also [Remove Maven dependency mechanism for use in other projects from the documentation](https://github.com/paulissoft/oracle-tools/issues/41).

[//]: # ()
[//]: # (#### Database POM)
[//]: # ()
[//]: # (The .../projects/YOUR-PROJECT/db/pom.xml may have as parent:)
[//]: # (Add this to the Database POM:)
[//]: # ()
[//]: # (```)
[//]: # (  <parent>)
[//]: # (    <groupId>com.paulissoft.oracle-tools</groupId>)
[//]: # (    <artifactId>db</artifactId>)
[//]: # (    <version>YOUR VERSION</version>)
[//]: # (    <relativePath></relativePath>)
[//]: # (  </parent>)
[//]: # ()
[//]: # (  <properties>)
[//]: # (    <oracle-tools.db.version>YOUR VERSION</oracle-tools.db.version>)
[//]: # (    <db.dependency>true</db.dependency>)
[//]: # (  </properties>)
[//]: # (```)
[//]: # ()
[//]: # (If you want to use the ORCL database from the Oracle Tools conf/src directory)
[//]: # (you have to add this dependency as well:)
[//]: # ()
[//]: # (```)
[//]: # (    <conf.dependency>true</conf.dependency>)
[//]: # (```)
[//]: # ()
[//]: # (Then you can run for instance:)
[//]: # ()
[//]: # (```)
[//]: # ($ mvn -Pdb-install -Ddb=orcl -Ddb.password=...)
[//]: # (```)
[//]: # ()
[//]: # (to get a connection to the local database with service name ORCL on port 1521,)
[//]: # (the Oracle default.)
[//]: # ()
[//]: # ()
[//]: # (#### Apex POM)
[//]: # ()
[//]: # (Add this to the Apex POM:)
[//]: # ()
[//]: # (```)
[//]: # (  <parent>)
[//]: # (    <groupId>com.paulissoft.oracle-tools</groupId>)
[//]: # (    <artifactId>apex</artifactId>)
[//]: # (    <version>YOUR VERSION</version>)
[//]: # (    <relativePath></relativePath>)
[//]: # (  </parent>)
[//]: # ()
[//]: # (  <properties>)
[//]: # (    <oracle-tools.apex.version>YOUR VERSION</oracle-tools.apex.version>)
[//]: # (    <apex.dependency>true</apex.dependency>)
[//]: # (  </properties>)
[//]: # (```)
[//]: # ()
[//]: # (If you want to use the ORCL database from the Oracle Tools conf/src directory)
[//]: # (you have to add this dependency as well:)
[//]: # ()
[//]: # (```)
[//]: # (    <conf.dependency>true</conf.dependency>)
[//]: # (```)

