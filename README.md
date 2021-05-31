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

### various PL/SQL utilities

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
$ mvn -Ddb=<db from oracle-tools/build/conf> -Ddb.schema=<username> -Ddb.password=<password> -Ddb.operation=install validate flyway:migrate
```

#### Installing the APEX application

```
$ cd oracle-tools/tools/apex
$ mvn -Ddb=<db from oracle-tools/build/conf> -Ddb.schema=<username> -Ddb.password=<password> -Dapex.operation=import compile
```

## Using Oracle Tools in other Maven projects

### Database POM

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
  </properties>
  
  <!-- Needed for Flyway callbacks and Generate DDL scripts -->
  <dependencies>
    <dependency>
      <groupId>com.paulissoft.oracle-tools</groupId>
      <artifactId>db</artifactId>
      <!-- type and classifier are needed when they are not the default -->
      <type>zip</type>
      <classifier>src</classifier>
    </dependency>
  </dependencies>

  <build>
    <resources/>
    <plugins>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
```

If you want to use the ORCL database from the Oracle Tools conf/src directory
you have to add this dependency as well:

```
    <dependency>
      <groupId>com.paulissoft.oracle-tools</groupId>
      <artifactId>conf</artifactId>
      <!-- type and classifier are needed when they are not the default -->
      <type>zip</type>
      <classifier>src</classifier>
    </dependency>
```

Then you can run for instance:

```
$ mvn -Pdb-install -Ddb=orcl -Ddb.password=...
```

to get a connection to the local database with service name ORCL on port 1521,
the Oracle default.


### Apex POM

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
  </properties>
  
  <!-- Needed for Apex Export/Import scripts -->
  <dependencies>
    <dependency>
      <groupId>com.paulissoft.oracle-tools</groupId>
      <artifactId>apex</artifactId>
      <!-- type and classifier are needed when they are not the default -->
      <type>zip</type>
      <classifier>src</classifier>
    </dependency>
  </dependencies>

  <build>
    <resources/>
    <plugins>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
```
