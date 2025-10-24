CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" AUTHID CURRENT_USER
is 

/**
This package defines functions and procedures used by Flyway callbacks.
**/

procedure "beforeMigrate"
( p_oracle_tools_schema_msg in varchar2 default $$PLSQL_UNIT_OWNER -- Oracle tools schema for msg framework
);
/** The Flyway beforeMigrate callback. **/

procedure "beforeEachMigrate";
/** The Flyway beforeEachMigrate callback. **/

procedure "afterMigrate"
( p_compile_all in boolean -- Do we need to compile all?
, p_reuse_settings in boolean -- Do we reuse PL/SQL settings?
, p_oracle_tools_schema_msg in varchar2 default $$PLSQL_UNIT_OWNER -- Oracle tools schema for msg framework
);
/** The Flyway afterMigrate callback. **/

procedure setup_session
( p_plsql_warnings in varchar2 default 'DISABLE:ALL' -- For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'"
, p_plscope_settings in varchar2 default null -- For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'"
);
/**
Setup a session.

Used by Flyway to define PL/SQL flags (PLSQL_CCFlags), PL/SQL warnings (PLSQL_WARNINGS) and PL/Scope settings (PLSCOPE_SETTINGS).

PLSQL_CCFlags:
- $$Debug (is package DBUG available?)
- $$Testing (is utPLSQL package UT available?)
**/

procedure compile_objects
( p_compile_all in boolean -- Do we need to compile all?
, p_reuse_settings in boolean -- Do we reuse PL/SQL settings?
);
/** Compile objects in the current schema. **/

type t_compiler_message_tab is table of all_errors%rowtype;

function show_compiler_messages
( p_object_schema in varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA') -- The schema owner of the objects to show.
, p_object_type in varchar2 default null -- The object type (may be a DBMS_METADATA object type).
, p_object_names in varchar2 default null -- A comma separated list of object names.
, p_object_names_include in integer default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_exclude_objects in clob default null -- A list of unique identification expressions to exclude where you can use O/S wild cards (* and ?).
, p_include_objects in clob default null -- A list of unique identification expressions to include where you can use O/S wild cards (* and ?).
, p_recompile in integer default 0 -- Do we need to recompile the objects before showing the messages? 0 means no.
, p_plsql_warnings in varchar2 default 'ENABLE:ALL' -- For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'".
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL' -- For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'".
)
return t_compiler_message_tab -- A list of USER_ERRORS rows ordered by name, type, sequence.
pipelined;
/** Show compiler messages. **/

type t_message_tab is table of varchar2(4000 char);

function format_compiler_messages
( p_object_schema in varchar2 default sys_context('USERENV', 'CURRENT_SCHEMA') -- The schema owner of the objects to show.
, p_object_type in varchar2 default null -- The object type (may be a DBMS_METADATA object type).
, p_object_names in varchar2 default null -- A comma separated list of object names.
, p_object_names_include in integer default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_exclude_objects in clob default null -- A list of unique identification expressions to exclude where you can use O/S wild cards (* and ?).
, p_include_objects in clob default null -- A list of unique identification expressions to include where you can use O/S wild cards (* and ?).
, p_recompile in integer default 0 -- Do we need to recompile the objects before showing the messages? 0 means no.
, p_plsql_warnings in varchar2 default 'ENABLE:ALL' -- For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'".
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL' -- For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'".
)
return t_message_tab -- A list of USER_ERRORS rows ordered by name, type, sequence.
pipelined;
/** Format compiler messages. **/

function purge_flyway_table
( p_table_name in varchar2
, p_nr_months_to_keep in positiven default 12
)
return integer;
/**

Purge the Flyway table:
1. keep all entries with a "version" not null (non-repeatables)
2. always keep the latest entry per repeatable script ("version" null) and keep at most p_nr_months_to_keep for older entries

**/

procedure check_object_valid
( p_object_type in all_objects.object_type%type -- The object type (TYPE, PACKAGE, ...), case insensitive
, p_object_name in all_objects.object_name%type -- The object name, case insensitive
, p_owner in all_objects.owner%type default sys_context('USERENV', 'CURRENT_SCHEMA') -- The owner, case insensitive
);
/**
Check whether a database object is valid with a query like this:

```
select  count(*)
from    all_objects obj
where   obj.owner in (p_owner, upper(p_owner))
and     obj.object_type in (p_object_type, upper(p_object_type))
and     obj.object_name in (p_object_name, upper(p_object_name))
and     obj.status = 'VALID'
```

If the count is not 1, raise_application_error(-20000, ...) is called with an appropriate error message.

Can be used in incremental scripts that create a package or type specification but where the specification may not be valid.
**/

end cfg_install_pkg;
/

