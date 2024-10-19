# How DDL is generated

This document explains how DDL is generated using the DDL API.

## Table of contents

1. [Introduction](#introduction)
2. [Maven profile *db-generate-ddl-full*](#maven-profile-db-generate-ddl-full)
   1. [Ant target *generate-ddl-full-scripts*](#ant-target-generate-ddl-full-scripts)
      1. [Examples of (temporary) scripts](#examples-of-temporary-scripts)
      2. [`oracle-tools/db/src/scripts/GenerateDDL.java`](#oracle-toolsdbsrcscriptsgenerateddljava)
      3. [`oracle-tools/db/src/scripts/generate_ddl.pl`](#oracle-toolsdbsrcscriptsgenerate_ddlpl)
   2. [Ant target *generate-ddl-full-uninstall*](#ant-target-generate-ddl-full-uninstall)
3. [Oracle packages](#oracle-packages) 
   1. [*oracle_tools.pkg_ddl_util.display_ddl_schema*](#oracle_toolspkg_ddl_utildisplay_ddl_schema)
      1. [*oracle_tools.pkg_schema_object_filter.get_schema_objects*](#oracle_toolspkg_schema_object_filterget_schema_objects)
      2. [*oracle_tools.pkg_ddl_util.get_schema_ddl*](#oracle_toolspkg_ddl_utilget_schema_ddl)
      3. [*oracle_tools.pkg_ddl_util.sort_objects_by_deps*](#oracle_toolspkg_ddl_utilsort_objects_by_deps)
3. [Oracle object types](#oracle-object-types)
   1. [oracle_tools.t_schema_ddl_tab](#oracle_toolst_schema_ddl_tab)
   2. [oracle_tools.t_schema_ddl](#oracle_toolst_schema_ddl)
   3. [oracle_tools.t_schema_object_tab](#oracle_toolst_schema_object_tab)
   4. [oracle_tools.t_schema_object](#oracle_toolst_schema_object)
   5. [oracle_tools.t_ddl_tab](#oracle_toolst_ddl_tab)
   6. [oracle_tools.t_ddl](#oracle_toolst_ddl)
   7. [oracle_tools.t_text_tab](#oracle_toolst_text_tab)

## Introduction

These are the high level actions:
1. Invoke application Maven POM with profile *db-generate-ddl-full* that invokes the parent Maven POM `oracle-tools/db/pom.xl` that will
   invoke Ant build file `oracle-tools/db/src/scripts/generate_ddl.xml` with target *generate-ddl-full* that will finally invoke:
   1. Ant target *generate-ddl-full-scripts*
   2. Ant target *generate-ddl-full-uninstall*

## Maven profile *db-generate-ddl-full*

### Ant target *generate-ddl-full-scripts*

Creates a temporary file that with the relevant properties from the application POM file.

That temporary file will serve as input property file for `oracle-tools/db/src/scripts/GenerateDDL.java`.

Then a (temporary) SQL output file will be created by the database that is parsed by Perl script `oracle-tools/db/src/scripts/generate_ddl.pl`.

The Perl script splits this SQL output file into Flyway scripts in the application `src/full` folder.

#### Examples of (temporary) scripts

Here an example for this application POM file:

```
<?xml version="1.0" encoding="windows-1252" ?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">

  <parent>
    <groupId>com.bluecurrent.backoffice</groupId>
    <artifactId>db</artifactId>
    <version>${revision}</version>
  </parent>

  <modelVersion>4.0.0</modelVersion>
  <groupId>com.bluecurrent.backoffice.db</groupId>
  <artifactId>BC_LP</artifactId>
  <packaging>pom</packaging>
  <description>BC_LP component</description>

  <properties>
    <db.generate.full.strip.source.schema>0</db.generate.full.strip.source.schema>
    <db.include.objects>      
BC_LP:FUNCTION:BLOB_TO_BASE64:::::::
BC_LP:FUNCTION:GET_LICENSE_PLATE:::::::
    </db.include.objects>
    <db.test.phase>none</db.test.phase>
  </properties>

  <build>
    <resources />
  </build>

</project>
```

Temporary file (input for `oracle-tools/db/src/scripts/GenerateDDL.java`):

```
#Mon, 14 Oct 2024 10:58:28 +0200

source.schema=
source.db.name=
target.schema=BC_LP
target.db.name=
object.type=
object.names.include=
object.names=
skip.repeatables=0
interface=pkg_ddl_util v5
transform.params=
exclude.objects=
include.objects=BC_LP\:FUNCTION\:BLOB_TO_BASE64\:\:\:\:\:\:\:\nBC_LP\:FUNCTION\:GET_LICENSE_PLATE\:\:\:\:\:\:\:
owner=ORACLE_TOOLS
```

An excerpt of the (temporary) SQL output (input for Perl script `oracle-tools/db/src/scripts/generate_ddl.pl`):

```
/*
-- JDBC url - username : jdbc:oracle:thin:@bc_dev - BC_PROXY[BC_LP]
-- source schema       : BC_LP
-- source database link: 
-- target schema       : 
-- target database link: 
-- object type         : 
-- object names include: 
-- object names        : 
-- skip repeatables    : 0
-- interface           : pkg_ddl_util v5
-- transform params    : 
-- exclude objects     : 
-- include objects     : BC_LP:FUNCTION:BLOB_TO_BASE64:::::::
BC_LP:FUNCTION:GET_LICENSE_PLATE:::::::
-- owner               : ORACLE_TOOLS
*/
-- pkg_ddl_util v5
-- ddl info: CREATE;BC_LP;FUNCTION;BLOB_TO_BASE64;;;;;;;;1
CREATE OR REPLACE EDITIONABLE FUNCTION "BC_LP"."BLOB_TO_BASE64" (P_BLOB BLOB) RETURN CLOB as
```

#### `oracle-tools/db/src/scripts/GenerateDDL.java`

Invokes Oracle package *oracle_tools.p_generate_ddl* that in turn invokes *oracle_tools.pkg_ddl_util.display_ddl_schema*.

#### `oracle-tools/db/src/scripts/generate_ddl.pl`

### Ant target *generate-ddl-full-uninstall*

## Oracle packages

### *oracle_tools.pkg_ddl_util.display_ddl_schema*

Returns: [oracle_tools.t_schema_ddl_tab](#oracle_toolst_schema_ddl_tab)

Invokes:
1. *oracle_tools.pkg_schema_object_filter.get_schema_objects*
2. *oracle_tools.pkg_ddl_util.get_schema_ddl*
3. *oracle_tools.pkg_ddl_util.sort_objects_by_deps*

#### *oracle_tools.pkg_schema_object_filter.get_schema_objects*

Returns: [oracle_tools.t_schema_object_tab](#oracle_toolst_schema_object_tab)

```
create or replace type              t_schema_object_tab as table of oracle_tools.t_schema_object
```

#### *oracle_tools.pkg_ddl_util.get_schema_ddl*

Returns: [oracle_tools.t_schema_ddl_tab](#oracle_toolst_schema_ddl_tab)

#### *oracle_tools.pkg_ddl_util.sort_objects_by_deps*

## Oracle object types

### oracle_tools.t_schema_ddl_tab

```
create or replace type              t_schema_ddl_tab as table of oracle_tools.t_schema_ddl
```

### oracle_tools.t_schema_ddl

```
create or replace type              t_schema_ddl authid current_user as object
( obj oracle_tools.t_schema_object
, ddl_tab oracle_tools.t_ddl_tab
...
);
/
```
### oracle_tools.t_schema_object_tab

```
create or replace type              t_schema_object_tab as table of oracle_tools.t_schema_object
```

### oracle_tools.t_schema_object

```
create or replace type              t_schema_object authid current_user as object
( network_link$ varchar2(128 char)
, object_schema$ varchar2(128 char)
...
);
/
```

### oracle_tools.t_ddl_tab

```
create or replace type              t_ddl_tab as table of oracle_tools.t_ddl
```

### oracle_tools.t_ddl

```
create or replace type              t_ddl authid current_user as object
( ddl#$ integer
, verb$ varchar2(4000 char)
, text oracle_tools.t_text_tab
...
);
/
```

### oracle_tools.t_text_tab

```
create or replace TYPE                "T_TEXT_TAB" AS TABLE OF VARCHAR2(4000 CHAR)
```
