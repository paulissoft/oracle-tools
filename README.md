# Oracle tools

This project contains:
- Maven build software for deploying Oracle software (database and Apex).
- Apex and database tools installed by the build software.

## Maven build

See the various POM files.

## Tools

A set of Oracle tools for Oracle projects.

Currently it includes:
- a PL/SQL DDL generator (that can be used to describe your deployment).
- an Apex application to load spreadsheet files into a database table/view.
- various PL/SQL utilities to help with development.

### PL/SQL DDL generator

### Apex application to load spreadsheet files

The following MIME spreadsheet types (with extension between parentheses) are supported:
- application/vnd.openxmlformats-officedocument.spreadsheetml.sheet (.xlsx)
- application/vnd.ms-excel (.xls)
- application/vnd.ms-excel.sheet.binary.macroEnabled.12 (.xlsb)
- application/vnd.oasis.opendocument.spreadsheet (.ods)

This project depends on the ExcelTable GitHub project:
https://github.com/mbleron/ExcelTable.git.

### Various PL/SQL utilities

Utilities to enable/disable constraints, manage Apex messages and so on.

## Installation of all the tools

The installation of an Oracle database and Oracle APEX is out of scope.

### Setting up the database schema(s)

Creating the database schema(s) for the ExcelTable and tools software is out of scope.

### Installing ExcelTable

See the [ExcelTable README](https://github.com/mbleron/ExcelTable) for further instructions.

When the Oracle tools schema differs from this schema then you must grant privileges like this:

```
SQL> grant execute on ExcelTable to <Oracle tools schema>;
```


### Installing Oracle tools from source

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

## Using Oracle Tools in other Maven projects

### Using Oracle Tools on the file system on the same level as your project

This is an example file layout:


```
.../projects/oracle-tools
.../projects/your-project
```

#### Database POM

The .../projects/your-project/db/pom.xml may have as parent:

```
<parent>
  <groupId>com.paulissoft.oracle-tools</groupId>
  <artifactId>db</artifactId>
  <version>${revision}</version>
  <relativePath>../../oracle-tools/db</relativePath>
</parent>
```

#### Apex POM

The .../projects/your-project/apex/pom.xml may have as parent:

```
<parent>
  <groupId>com.paulissoft.oracle-tools</groupId>
  <artifactId>apex</artifactId>
  <version>${revision}</version>
  <relativePath>../../oracle-tools/apex</relativePath>
</parent>
```

### Using Maven dependencies

#### Database POM

The .../projects/your-project/db/pom.xml may have as parent:
Add this to the Database POM:

```
  <parent>
    <groupId>com.paulissoft.oracle-tools</groupId>
    <artifactId>db</artifactId>
    <version>YOUR VERSION</version>
    <relativePath></relativePath>
  </parent>

  <properties>
    <oracle-tools.db.version>YOUR VERSION</oracle-tools.db.version>
    <db.dependency>true</db.dependency>
  </properties>
```

If you want to use the ORCL database from the Oracle Tools conf/src directory
you have to add this dependency as well:

```
    <conf.dependency>true</conf.dependency>
```

Then you can run for instance:

```
$ mvn -Pdb-install -Ddb=orcl -Ddb.password=...
```

to get a connection to the local database with service name ORCL on port 1521,
the Oracle default.


#### Apex POM

Add this to the Apex POM:

```
  <parent>
    <groupId>com.paulissoft.oracle-tools</groupId>
    <artifactId>apex</artifactId>
    <version>YOUR VERSION</version>
    <relativePath></relativePath>
  </parent>

  <properties>
    <oracle-tools.apex.version>YOUR VERSION</oracle-tools.apex.version>
    <apex.dependency>true</apex.dependency>
  </properties>
```

If you want to use the ORCL database from the Oracle Tools conf/src directory
you have to add this dependency as well:

```
    <conf.dependency>true</conf.dependency>
```

