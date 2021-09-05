CREATE OR REPLACE PACKAGE "CFG_INSTALL_PKG" authid current_user
is 

type t_compiler_messages_tab is table of all_errors%rowtype;

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
, p_plscope_settings in varchar2 default null
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
 * Show compiler messages.
 *
 * @param p_object_schema         The schema owner of the objects to show.
 * @param p_object_names          A comma separated list of object names.
 * @param p_object_names_include  How to treat the object name list: include (1), exclude (0) or don't care (null)?
 * @param p_recompile             Do we need to recompile the objects before showing the messages? 0 means no.
 * @param p_plsql_warnings        For "alter session set PLSQL_WARNINGS = '<p_plsql_warnings>'".
 * @param p_plscope_settings      For "alter session set PLSCOPE_SETTINGS = '<p_plscope_settings>'".
 *
 * @return A list of USER_ERRORS rows ordered by name, type, sequence.
 */
function show_compiler_messages
( p_object_schema in varchar2 default user
, p_object_names in varchar2 default null
, p_object_names_include in integer default null
, p_recompile in integer default 0
, p_plsql_warnings in varchar2 default 'ENABLE:ALL'
, p_plscope_settings in varchar2 default 'IDENTIFIERS:ALL'
)
return t_compiler_messages_tab
pipelined;

end cfg_install_pkg;
/

