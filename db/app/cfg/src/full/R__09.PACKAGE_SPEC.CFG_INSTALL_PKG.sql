CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" AUTHID CURRENT_USER
is 

type t_compiler_message_tab is table of all_errors%rowtype;

type t_message_tab is table of varchar2(4000 char);

/**
This package defines functions and procedures used by Flyway callbacks.
**/

procedure "afterMigrate"
( p_compile_all in boolean -- Do we need to compile all?
, p_reuse_settings in boolean -- Do we reuse PL/SQL settings?
);
/** The Flyway afterMigrate callback. **/

procedure "beforeEachMigrate";
/** The Flyway beforeEachMigrate callback. **/

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

function show_compiler_messages
( p_object_schema in varchar2 default user -- The schema owner of the objects to show.
, p_object_type in varchar2 default null -- The object type (may be a DBMS_METADATA object type).
, p_object_names in varchar2 default null -- A comma separated list of object names.
, p_object_names_include in integer default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_recompile in integer default 0 -- Do we need to recompile the objects before showing the messages? 0 means no.
, p_plsql_warnings in varchar2 default 'ENABLE:ALL' -- For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'".
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL' -- For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'".
)
return t_compiler_message_tab -- A list of USER_ERRORS rows ordered by name, type, sequence.
pipelined;
/** Show compiler messages. **/

function format_compiler_messages
( p_object_schema in varchar2 default user -- The schema owner of the objects to show.
, p_object_type in varchar2 default null -- The object type (may be a DBMS_METADATA object type).
, p_object_names in varchar2 default null -- A comma separated list of object names.
, p_object_names_include in integer default null -- How to treat the object name list: include (1), exclude (0) or don't care (null)?
, p_recompile in integer default 0 -- Do we need to recompile the objects before showing the messages? 0 means no.
, p_plsql_warnings in varchar2 default 'ENABLE:ALL' -- For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'".
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL' -- For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'".
)
return t_message_tab -- A list of USER_ERRORS rows ordered by name, type, sequence.
pipelined;
/** Format compiler messages. **/

end cfg_install_pkg;
/

