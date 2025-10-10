CREATE OR REPLACE PACKAGE "CFG_INSTALL_DDL_PKG" AUTHID CURRENT_USER
is 

/**
This package defines functions and procedures used by Flyway increments (or more in general by DDL change operations).
**/

-- *** ddl_execution_settings ***
c_ddl_lock_timeout           constant naturaln := 60; -- alter session set ddl_lock_timeout = p_ddl_lock_timeout;
c_dry_run                    constant boolean  := false; -- must commands be executed or just shown via dbms_output?
c_reraise_original_exception constant boolean  := true; -- raise original exception or use raise_application_error(-20000, ..., true)
c_explicit_commit            constant boolean  := true; -- explicit commit before and after statements?
c_verbose                    constant boolean  := cfg_pkg.c_testing;
                    
type t_ignore_sqlcode_tab is table of pls_integer; -- must be a nested table
type t_column_tab is table of all_tab_columns.column_name%type; -- must be a nested table

-- *** generic ***
-- ORA-00955: name is already used by an existing object
c_object_already_exists constant pls_integer := -955;

-- *** column_ddl ***
-- ORA-01430: column being added already exists in table
c_column_already_exists constant pls_integer := -1430;
-- ORA-00904: "NAME": invalid identifier
c_column_does_not_exist constant pls_integer := -904;
c_ignore_sqlcodes_column_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_column_already_exists, c_column_does_not_exist);
 
-- *** table_ddl **
-- ORA-00955: name is already used by an existing object
c_table_already_exists constant pls_integer := c_object_already_exists;
-- ORA-00942: table or view does not exist
c_table_does_not_exist constant pls_integer := -942;
c_ignore_sqlcodes_table_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_table_already_exists, c_table_does_not_exist);

-- *** constraint_ddl ***
-- ORA-02261: such unique or primary key already exists in the table
c_unique_key_already_exists constant pls_integer := -2261;
-- ORA-02264: name already used by an existing constraint
c_check_already_exists constant pls_integer := -2264;
-- ORA-02260: table can have only one primary key
c_primary_key_already_exists constant pls_integer := -2260;
-- ORA-02275: such a referential constraint already exists in the table
c_foreign_key_already_exists constant pls_integer := -2275;
-- ORA-02443: Cannot drop constraint  - nonexistent constraint
c_constraint_does_not_exist constant pls_integer := -2443;
c_ignore_sqlcodes_constraint_ddl constant t_ignore_sqlcode_tab :=
  t_ignore_sqlcode_tab
  ( c_unique_key_already_exists
  , c_check_already_exists
  , c_primary_key_already_exists
  , c_foreign_key_already_exists
  , c_constraint_does_not_exist
  );

-- *** comment_ddl ***
c_ignore_sqlcodes_comment_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(); -- there are no SQL codes to ignore

-- *** index_ddl ***
-- ORA-01418: specified index does not exist
-- ORA-00955: name is already used by an existing object
c_index_already_exists constant pls_integer := c_object_already_exists;
c_index_does_not_exist constant pls_integer := -1418;
c_ignore_sqlcodes_index_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_index_already_exists, c_index_does_not_exist);

-- *** trigger_ddl ***
-- ORA-04081: trigger 'FKNTM_BC_CHARGEPOINT_TARIFF_GROUPS' already exists
c_trigger_already_exists constant pls_integer := -4081;
-- ORA-04080: trigger 'BC_CP_CHARGE_PROFILE_SCHED_BI' does not exist
c_trigger_does_not_exist constant pls_integer := -4080;
c_ignore_sqlcodes_trigger_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_trigger_already_exists, c_trigger_does_not_exist);

-- *** view_ddl **
-- ORA-00955: name is already used by an existing object
c_view_already_exists constant pls_integer := c_object_already_exists;
-- ORA-00942: table or view does not exist
c_view_does_not_exist constant pls_integer := -942;
c_ignore_sqlcodes_view_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_view_already_exists, c_view_does_not_exist);

procedure set_ddl_execution_settings
( p_ddl_lock_timeout in natural default null -- alter session set ddl_lock_timeout = p_ddl_lock_timeout;
, p_dry_run in boolean default null -- must commands be executed or just shown via dbms_output?
, p_reraise_original_exception in boolean default null -- raise original exception or use raise_application_error(-20000, ..., true)
, p_explicit_commit in boolean default null -- explicit commit before and after statements?
, p_verbose in boolean default null -- set verbose to true/false or keep the default (null)
);
/**
Change DDL execution settings that are stored for this session.

When a parameter is null, the corresponding cached variable is not set (i.e. not changed).
So this procedure can be used to change 0, 1, 2, 3 or 4 parameters.
**/

procedure reset_ddl_execution_settings;
/** Reset to the default values, i.e. c_ddl_lock_timeout, c_dry_run, c_reraise_original_exception, c_explicit_commit. **/

procedure column_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY, DROP or RENAME
, p_table_name in user_tab_columns.table_name%type -- The table name
, p_column_name in user_tab_columns.column_name%type -- The column name
, p_extra in varchar2 default null -- To add after the column name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_column_ddl -- SQL codes to ignore
);
/**
Issues a:
- 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' (' || p_column_name || ' ' || p_extra || ')' (no RENAME)
- 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' COLUMN ' || p_column_name || ' ' || p_extra (RENAME)
**/

procedure table_ddl
( p_operation in varchar2 -- The operation: usually CREATE, ALTER or DROP
, p_table_name in user_tab_columns.table_name%type -- The table name
, p_extra in varchar2 default null -- To add after the table name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_table_ddl -- SQL codes to ignore
);
/**
Issues a p_operation || ' TABLE ' || p_table_name || ' ' || p_extra
**/

procedure check_constraint_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY, RENAME or DROP
, p_table_name in user_constraints.table_name%type -- The table name
, p_constraint_name in user_constraints.constraint_name%type -- The constraint name
, p_search_condition_vc in user_constraints.search_condition_vc%type default null -- The check constraint search condition
, p_column_tab in t_column_tab default null -- The column names to check for in ascending order (there is no order in USER_CONS_COLUMNS for check constraints)
, p_extra in varchar2 default null -- To add after the constraint name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_constraint_ddl -- SQL codes to ignore
);
/**
Issues a "'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || p_constraint_name || ' ' || p_extra" command.

The table, constraint, search condition and columns will be used
to lookup exactly one check constraint (when it should exist, i.e. operation <> 'ADD').

You can also use `constraint_ddl`, but then you will miss the search condition lookup.
**/

procedure constraint_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY, RENAME or DROP
, p_table_name in user_constraints.table_name%type -- The table name
, p_constraint_name in user_constraints.constraint_name%type -- The constraint name
, p_constraint_type in user_constraints.constraint_type%type default null -- The constraint type
, p_column_tab in t_column_tab default null -- The column names to check for (in ascending order for check constraints else the order from USER_CONS_COLUMNS)
, p_extra in varchar2 default null -- To add after the constraint name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_constraint_ddl -- SQL codes to ignore
);
/**
Issues a "'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || p_constraint_name || ' ' || p_extra" command.

The table, constraint, constraint type and columns will be used
to lookup exactly one check constraint (when it should exist, i.e. operation <> 'ADD').

You can also use `check_constraint_ddl` for check constraints which gives you the option to use the search condition.
**/

procedure comment_ddl
( p_table_name in user_tab_columns.table_name%type -- The table name
, p_column_name in user_tab_columns.column_name%type default null -- The column name (empty for a table comment)
, p_comment in varchar2 default null -- The comment (empty to remove)
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_comment_ddl -- SQL codes to ignore
);
/**
Issues:
a. p_column_name is not null: 'COMMENT ON COLUMN ' || p_table_name || '.' || p_column_name || ' IS ''' || p_comment || ''''
b. p_column_name is null: 'COMMENT ON TABLE ' || p_table_name || ' IS ''' || p_comment || ''''
**/

procedure index_ddl
( p_operation in varchar2 -- Usually CREATE, ALTER or DROP
, p_index_name in user_indexes.index_name%type -- The index name
, p_table_name in user_indexes.table_name%type default null -- The table name
, p_column_tab in t_column_tab default null -- The column names of the index (in that order). May be used when for operation CREATE or ALTER with a RENAME with index_name containing the wildcard %.
, p_extra in varchar2 default null -- The extra to add to the DDL statement
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_index_ddl -- SQL codes to ignore
);
/**
Issues:
a. p_table_name is not null: p_operation || ' ' || p_index_name || ' ON ' || p_table_name || ' ' || p_extra
b. p_table_name is null: p_operation || ' ' || p_index_name || p_extra
**/

procedure trigger_ddl
( p_operation in varchar2 -- Usually CREATE, CREATE OR REPLACE, ALTER or DROP
, p_trigger_name in user_triggers.trigger_name%type -- The trigger name
, p_trigger_extra in varchar2 default null -- The extra to add after the trigger name
, p_table_name in user_triggers.table_name%type default null -- The table name
, p_extra in varchar2 default null -- The extra to add to the DDL statement
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_trigger_ddl -- SQL codes to ignore
);
/**
Issues:
a. p_table_name is not null: p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra || ' ON ' || p_table_name || chr(10) || p_extra
c. p_table_name is null: p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra
**/

procedure view_ddl
( p_operation in varchar2 -- The operation: usually CREATE [OR REPLACE], ALTER or DROP
, p_view_name in user_views.view_name%type -- The view name
, p_extra in varchar2 default null -- To add after the view name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_view_ddl -- SQL codes to ignore
);
/**
Issues a p_operation || ' VIEW ' || p_view_name || ' ' || p_extra
**/


$if cfg_pkg.c_testing $then

--%suitepath(CFG)
--%suite
--%rollback(manual)

--%beforeeach
procedure ut_setup;

--%aftereach
procedure ut_teardown;

--%test
procedure ut_column_ddl;

--%test
--%throws(cfg_install_ddl_pkg.c_column_already_exists)
procedure ut_column_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_column_does_not_exist)
procedure ut_column_does_not_exist;

--%test
procedure ut_table_ddl;

--%test
--%throws(cfg_install_ddl_pkg.c_table_already_exists)
procedure ut_table_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_table_does_not_exist)
procedure ut_table_does_not_exist;

--%test
procedure ut_constraint_ddl;

--%test
--%throws(cfg_install_ddl_pkg.c_primary_key_already_exists)
procedure ut_pk_constraint_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_unique_key_already_exists)
procedure ut_uk_constraint_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_foreign_key_already_exists)
procedure ut_fk_constraint_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_check_already_exists)
procedure ut_ck_constraint_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_constraint_does_not_exist)
procedure ut_pk_constraint_does_not_exist;

--%test
--%throws(cfg_install_ddl_pkg.c_constraint_does_not_exist)
procedure ut_uk_constraint_does_not_exist;

--%test
--%throws(cfg_install_ddl_pkg.c_constraint_does_not_exist)
procedure ut_fk_constraint_does_not_exist;

--%test
--%throws(cfg_install_ddl_pkg.c_constraint_does_not_exist)
procedure ut_ck_constraint_does_not_exist;

--%test
procedure ut_rename_constraint;

--%test
procedure ut_rename_index;

--%test
procedure ut_view_ddl;

--%test
--%throws(cfg_install_ddl_pkg.c_view_already_exists)
procedure ut_view_already_exists;

--%test
--%throws(cfg_install_ddl_pkg.c_view_does_not_exist)
procedure ut_view_does_not_exist;

$end

end cfg_install_ddl_pkg;
/

