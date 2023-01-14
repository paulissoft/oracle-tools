# PATO (Paulissoft Application Tools for Oracle)

This project contains:
- Maven build software for deploying Oracle software (database and Apex).
- Apex and database tools installed by the build software.

For people interested in the ideas behind this project and more in-depth knowledge about PATO there is [a book on Leanpub.com](https://leanpub.com/build-oracle-apex-application).

## Maven build

See the various POM files. 

There is also [a Python GUI for PATO as an alternative for the Maven command line](https://github.com/paulissoft/pato-gui).

And finally for CI/CD purposes there is a Jenkins CI/CD setup in the `jenkins` folder, but please read the book for more information.

## Tools

A set of application tools for Oracle developers.

Currently it includes:
- a PL/SQL DDL generator (that can be used to describe your deployment).
- an Apex application to load spreadsheet files into a database table/view.
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

### Various PL/SQL utilities

Utilities to enable/disable constraints, manage Apex messages and so on.

See the sub folders in `db/app/`.

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

