CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" AUTHID CURRENT_USER
is 

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

end cfg_install_pkg;
/

