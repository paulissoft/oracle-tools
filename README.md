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
$ git clone https://github.com/paulissoft/oracle_tools.git
```

#### Installing the database software

```
$ cd oracle_tools/tools/db
$ mvn -Ddb=<db from oracle_tools/build/conf> -Ddb.schema=<username> -Ddb.password=<password> -Ddb.operation=install validate flyway:migrate
```

#### Installing the APEX application

```
$ cd oracle_tools/tools/apex
$ mvn -Ddb=<db from oracle_tools/build/conf> -Ddb.schema=<username> -Ddb.password=<password> -Dapex.operation=import compile
```

## Using Oracle Tools in other Maven projects

### Database POM

Add this to the Database POM:

```
  <parent>
    <groupId>com.paulissoft.tools</groupId>
    <artifactId>db</artifactId>
    <version>YOUR VERSION</version>
    <relativePath></relativePath>
  </parent>

  <properties>
    <oracle_tools.version>${project.parent.version}</oracle_tools.version>
  </properties>

	<!-- Needed for Flyway callbacks and Generate DDL scripts -->
  <dependencies>
    <dependency>
      <groupId>com.paulissoft.build</groupId>
      <artifactId>db</artifactId>
      <version>${project.parent.version}</version>
      <classifier>project</classifier>
      <type>zip</type>
      <!-- Make sure this isn't included on any classpath-->
      <scope>provided</scope>
    </dependency>
  </dependencies>

  <build>
    <resources/>
    <plugins>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
        <!-- Configuration won't be propagated to children -->
        <inherited>false</inherited>
      </plugin>
    </plugins>
  </build>
```
### Apex POM

Add this to the Apex POM:

```
  <parent>
    <groupId>com.paulissoft.tools</groupId>
    <artifactId>apex</artifactId>
    <version>YOUR VERSION</version>
    <relativePath></relativePath>
  </parent>

  <properties>
    <oracle_tools.version>${project.parent.version}</oracle_tools.version>
  </properties>

	<!-- Needed for Apex Export/Import scripts -->
  <dependencies>
    <dependency>
      <groupId>com.paulissoft.build</groupId>
      <artifactId>apex</artifactId>
      <version>${project.parent.version}</version>
      <classifier>project</classifier>
      <type>zip</type>
      <!-- Make sure this isn't included on any classpath-->
      <scope>provided</scope>
    </dependency>
  </dependencies>

  <build>
    <resources/>
    <plugins>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
        <!-- Configuration won't be propagated to children -->
        <inherited>false</inherited>
      </plugin>
    </plugins>
  </build>
```
