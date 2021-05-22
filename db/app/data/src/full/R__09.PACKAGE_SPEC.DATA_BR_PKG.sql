create or replace package data_br_pkg authid current_user is

type t_valid_count_rec is record
( owner all_tables.owner%type
, table_name all_tables.table_name%type
, valid integer
, cnt integer
);

type t_valid_count_tab is table of t_valid_count_rec;

type t_denormalisation_error_rec is record
( table_name user_tab_columns.table_name%type
, row_id varchar2(18) -- see ROWIDTOCHAR documentation
, column_name user_tab_columns.column_name%type
, value_denormalized varchar2(100)
, value_calculated varchar2(100)
);

type t_denormalisation_error_tab is table of t_denormalisation_error_rec;

-- a list of packages indexed by owner
type t_br_package_tab is table of all_procedures.object_name%type index by all_procedures.owner%type;

/**
 * This package has AUTHID CURRENT_USER so that it can be used by 
 * the schemas <system>_DATA and <system>_API in their packages.
 */

/**
 * Enable a business rule yes or no.
 *
 * If the business rule is implemented by a trigger, it is enabled or disabled.
 * When it is a constraint it is enabled or disabled.
 *
 * @param p_owner    The business rule owner
 * @param p_br_name  The business rule name
 * @param p_enable   Enabled yes or no
 */
procedure enable_br
( p_owner in varchar2 default sys_context('userenv', 'current_schema')
, p_br_name in varchar2
, p_enable in boolean
);

/**
 * Enable a business rule yes or no.
 *
 * This procedure will invoke 
 *
 *   execute immediate 'call ' || l_owner || '.' || p_br_package_tab(l_owner) || '.enable_br(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable
 *
 * for each owner in p_br_package_tab.
 *
 * @param p_br_package_tab  A list of packages for each schema involved in data integrity.
 * @param p_br_name         The business rule name
 * @param p_enable          Enabled yes or no
 */
procedure enable_br
( p_br_package_tab in t_br_package_tab
, p_br_name in varchar2
, p_enable in boolean
);

/**
 * Check that a business rule is enabled, yes or no.
 *
 * A business rule may be implemented by a trigger or a constraint.
 *
 * @param p_owner    The business rule owner
 * @param p_br_name  The business rule name
 * @param p_enable   Enabled yes or no
 */
procedure check_br
( p_owner in varchar2 default sys_context('userenv', 'current_schema')
, p_br_name in varchar2
, p_enable in boolean
);

/**
 * Check that a business rule is enabled, yes or no.
 *
 * This procedure will invoke 
 *
 *   execute immediate 'call ' || l_owner || '.' || p_br_package_tab(l_owner) || '.check_br(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable
 *
 * for each owner in p_br_package_tab.
 *
 * @param p_br_package_tab  A list of packages for each schema involved in data integrity.
 * @param p_br_name         The business rule name
 * @param p_enable          Enabled yes or no
 */
procedure check_br
( p_br_package_tab in t_br_package_tab
, p_br_name in varchar2
, p_enable in boolean
);

/**
 * Refresh a materialized view so it can be refreshed fast after.
 *
 * After:
 *
 *   ORA-12034: materialized view log on "BONUS_DATA"."BNS_OBJECTIVE_PLAN_DETAILS" younger than last refresh
 *
 * the materialized view can not no longer be refreshed fast (on commit). The solution is to completely refresh it.
 *
 * @param p_owner       The materialized view owner
 * @param p_mview_name  The materialized view name
 */
procedure refresh_mv
( p_owner in varchar2 default sys_context('userenv', 'current_schema')
, p_mview_name in varchar2
);

/**
 * Get the tables with a VALID column belonging to a constraint.
 *
 * @param p_owner            The owner of the table constraint
 * @param p_constraint_name  The constraint name
 *
 * @return A cursor returning owner and table name(s)
 */
function get_tables
( p_owner in varchar2 default sys_context('userenv', 'current_schema')
, p_constraint_name in varchar2
)
return sys_refcursor;

/**
 * Validate table with VALID columns.
 *
 * First get all the tables with a column VALID.
 * Next change VALID to p_valid if possible and if not catch the error.
 *
 * @param p_owner       The table schema
 * @param p_table_name  A wildcard for table names
 * @param p_commit      Commit after every update of column VALID for a table
 * @param p_valid       The value for VALID
 * @param p_error_tab   An array of error messages
 */
procedure validate_table
( p_owner in varchar2 default sys_context('userenv', 'current_schema')
, p_table_name in varchar2 default '%'
, p_commit in boolean default false
, p_valid in naturaln default 1
, p_error_tab out nocopy dbms_sql.varchar2_table
);

/**
 * Restore data integrity.
 *
 * Due to constraints or triggers being disabled or materialized views
 * enforcing business rules not being up to date, the data integrity may be at
 * danger. This procedure tries to restore that by calling refresh_mv(),
 * enable_br() and validate_table() from the business rule packages.
 *
 * The following dynamic calls will be made:
 *
 * - execute immediate 'call ' || l_owner || '.' || p_br_package_tab(l_owner) || '.refresh_mv(p_mview_name => ''%_MV_BR_%'')'
 *
 * - data_br_pkg.enable_br(p_br_package_tab; '%', true)
 *
 * - data_br_pkg.enable_br(p_br_package_tab, l_constraint_name, true)
 *
 * - execute immediate '
 *   declare
 *     l_error_tab dbms_sql.varchar2_table;
 *   begin
 *     ' || l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table(p_table_name => :1, p_commit => true, p_valid => 0, p_error_tab => l_error_tab);
 *   end;' using l_table_name;
 *
 * - execute immediate '
 *   declare
 *     l_error_tab dbms_sql.varchar2_table;
 *   begin
 *     ' || l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table(p_commit => true, p_error_tab => l_error_tab);
 *   end;';
 *
 *
 * @param p_br_package_tab  A list of packages for each schema involved in data integrity.
 */
procedure restore_data_integrity
( p_br_package_tab in t_br_package_tab
);

/**
 * Show tables with its valid or not count.
 *
 * @param p_cursor  A query cursor
 */
function show_valid_count
( p_owner in varchar2 default '%'
, p_table_name in varchar2 default '%'
)
return t_valid_count_tab
pipelined;

/**
 * Get all denormalisation errors.
 *
 * NOTE: There should be none.
 *
 * @param p_table_name  The table name(s) to check
 */

/* 
function get_denormalisation_errors
( p_table_name in varchar2 default '%'
)
return t_denormalisation_error_tab
pipelined;
*/

/**
 * Get denormalisation error count.
 *
 * NOTE: There should be none.
 *
 * @param p_table_name  The table name(s) to check
 */

/*
function denormalisation_error_count
( p_table_name in varchar2 default '%'
)
return integer;
*/

end data_br_pkg;
/
