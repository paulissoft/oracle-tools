CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" authid current_user
is 

type t_errors_tab is table of user_errors%rowtype;

/**
 * Setup a session.
 *
 * Used by Flyway to define PL/SQL flags (PLSQL_CCFlags) and PL/SQL warnings (PLSQL_WARNINGS).
 *
 * PLSQL_CCFlags:
 * <ol>
 * <li>$$Debug (is package DBUG available)</li>
 * <li>$$Testing (is utPLSQL package UT available)</li>
 * </ol>
 *
 * @param p_plsql_warnings  For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'"
 */
procedure setup_session
( p_plsql_warnings in varchar2 default 'DISABLE:ALL'
);

/**
 * Compile objects in the current schema.
 *
 * @param p_compile_all     Do we need to compile all?
 * @param p_reuse_settings  Do we reuse PL/SQL settings?
 */
procedure compile_objects
( p_compile_all in boolean
, p_reuse_settings in boolean
);

/**
 * Compile objects in the current schema and show the errors associated with them.
 *
 * <p>
 * Both package/type specifications and bodies will be compiled.
 * </p>
 *
 * @param p_object_names          A comma separated list of object names.
 * @param p_object_names_include  How to treat the object name list: include (1), exclude (0) or don't care (null)?
 * @param p_plsql_warnings        For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'"
 *
 * @return A list of USER_ERRORS rows ordered by name, type, sequence.
 */
function show_compile_errors
( p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
)
return t_errors_tab
pipelined;

end cfg_install_pkg;
/

