CREATE OR REPLACE PACKAGE "DATA_BR_PKG" authid current_user is

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

procedure enable_br
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The business rule owner
, p_br_name in varchar2 -- The business rule name
, p_enable in boolean -- Enable yes or no
);
/**
Enable a business rule yes or no.

If the business rule is implemented by a trigger, it is enabled or disabled.
When it is a constraint it is enabled or disabled.
**/

procedure enable_br
( p_br_package_tab in t_br_package_tab -- A list of packages for each schema involved in data integrity.
, p_br_name in varchar2 -- The business rule name
, p_enable in boolean -- Enable yes or no
);
/**
Enable a business rule yes or no.

This procedure will invoke 

```sql
execute immediate 'call ' || dbms_assert.sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.enable_br') || '(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable
```

for each owner in p_br_package_tab.
**/

procedure check_br
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The business rule owner
, p_br_name in varchar2 -- The business rule name
, p_enable in boolean -- Enabled yes or no
);
/**
Check that a business rule is enabled, yes or no.

A business rule may be implemented by a trigger or a constraint.
**/

procedure check_br
( p_br_package_tab in t_br_package_tab -- A list of packages for each schema involved in data integrity.
, p_br_name in varchar2 -- The business rule name
, p_enable in boolean -- Enabled yes or no
);
/**
Check that a business rule is enabled, yes or no.

This procedure will invoke 

```sql
execute immediate 'call ' || dbms_assert.sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.check_br') || '(p_br_name => :1, p_enable => :2)' using p_br_name, p_enable
```  

for each owner in p_br_package_tab.
**/

procedure refresh_mv
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The materialized view owner
, p_mview_name in varchar2 -- The materialized view name
);
/**
Refresh a materialized view so it can be refreshed fast after.

After this error message:

```
ORA-12034: materialized view log on "SCHEMA"."TABLE" younger than last refresh
```

the materialized view can not no longer be refreshed fast (on commit). The solution is to completely refresh it.
**/

function get_tables
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The owner of the table constraint
, p_constraint_name in varchar2 -- The constraint name
)
return sys_refcursor; -- A cursor returning owner and table name(s)
/** Get the tables with a VALID column belonging to a constraint. **/

procedure validate_table
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The table schema
, p_table_name in varchar2 default '%' -- A wildcard for table names
, p_commit in boolean default false -- Commit after every update of column VALID for a table
, p_valid in naturaln default 1 -- The value for VALID
, p_error_tab out nocopy dbms_sql.varchar2_table -- An array of error messages
);
/**
Validate table with VALID columns.

First get all the tables with a column VALID.
Next change VALID to p_valid if possible and if not catch the error.
**/

procedure enable_constraints
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The table schema
, p_table_name in varchar2 default '%' -- A wildcard for table names
, p_stop_on_error in boolean default true -- When enabling a constraint fails, the procedure will stop (yes/no)
, p_error_tab out nocopy dbms_sql.varchar2_table -- An array of error messages for constraints that could not be enabled
);
/**
Enable DISABLED constraints that have a VALIDATED clause, i.e. those constraints
where ALL_CONSTRAINTS.STATUS = 'DISABLED' and ALL_CONSTRAINTS.VALIDATED = 'VALIDATED'.
**/

procedure disable_constraints
( p_owner in varchar2 default sys_context('userenv', 'current_schema') -- The table schema
, p_table_name in varchar2 default '%' -- A wildcard for table names
, p_stop_on_error in boolean default true -- When disabling a constraint fails, the procedure will stop (yes/no)
, p_error_tab out nocopy dbms_sql.varchar2_table -- An array of error messages for constraints that could not be enabled
);
/**
Disable ENABLED constraints that have a VALIDATED clause, i.e. those constraints
where ALL_CONSTRAINTS.STATUS = 'ENABLED' and ALL_CONSTRAINTS.VALIDATED = 'VALIDATED'.
**/

procedure restore_data_integrity
( p_br_package_tab in t_br_package_tab -- A list of packages for each schema involved in data integrity.
);
/**
Restore data integrity.

Due to constraints or triggers being disabled or materialized views
enforcing business rules not being up to date, the data integrity may be at
danger. This procedure tries to restore that by calling refresh_mv(),
enable_br() and validate_table() from the business rule packages.

The following dynamic calls will be made:

- `execute immediate 'call ' || dbms_assert.sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.refresh_mv') || '(p_mview_name => ''%_MV_BR_%'')'`

- `data_br_pkg.enable_br(p_br_package_tab, '%', true)`

- `data_br_pkg.enable_br(p_br_package_tab, l_constraint_name, true)`

-
```sql
execute immediate '
declare
  l_error_tab dbms_sql.varchar2_table;
begin
  ' || dbms_assert.sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table') || '(p_table_name => :1, p_commit => true, p_valid => 0, p_error_tab => l_error_tab);
end;' using l_table_name
```  
-
```sql
execute immediate '
declare
  l_error_tab dbms_sql.varchar2_table;
begin
  ' || dbms_assert.sql_object_name(l_owner || '.' || p_br_package_tab(l_owner) || '.validate_table') || '(p_commit => true, p_error_tab => l_error_tab);
end;'
```
**/

function show_valid_count
( p_owner in varchar2 default '%'
, p_table_name in varchar2 default '%'
)
return t_valid_count_tab
pipelined;
/** Show tables with its valid or not count. **/


/* 
function get_denormalisation_errors
( p_table_name in varchar2 default '%' -- The table name(s) to check
)
return t_denormalisation_error_tab
pipelined;
*/
/**
 * Get all denormalisation errors.
 *
 * NOTE: There should be none.
 */


/*
function denormalisation_error_count
( p_table_name in varchar2 default '%' -- The table name(s) to check
)
return integer;
*/
/**
 * Get denormalisation error count.
 *
 * NOTE: There should be none.
 */

end data_br_pkg;
/

