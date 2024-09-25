CREATE OR REPLACE PACKAGE "CFG_INSTALL_DDL_PKG" AUTHID CURRENT_USER
is 

/**
This package defines functions and procedures used by Flyway increments (or more in general by DDL change operations).
**/

-- *** ddl_execution_settings ***
c_ddl_lock_timeout constant naturaln := 60; -- alter session set ddl_lock_timeout = p_ddl_lock_timeout;
c_dry_run constant boolean := false; -- Must commands be execute or just shown via dbms_output?


type t_ignore_sqlcode_tab is table of pls_integer;

-- *** generic ***
-- ORA-00955: name is already used by an existing object
c_object_already_exists constant pls_integer := -955;

-- *** column_ddl ***
-- ORA-01430: column being added already exists in table
c_column_already_exists constant pls_integer := -1430;
c_ignore_sqlcodes_column_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_column_already_exists);
 
-- *** table_ddl **
-- ORA-00955: name is already used by an existing object
c_table_already_exists constant pls_integer := c_object_already_exists;
-- ORA-00942: table or view does not exist
c_table_does_not_exist constant pls_integer := -942;
c_ignore_sqlcodes_table_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_table_already_exists, c_table_does_not_exist);

-- *** constraint_ddl ***
-- ORA-02264: name already used by an existing constraint
c_constraint_already_exists constant pls_integer := -2264;
-- ORA-02260: table can have only one primary key
c_primary_key_already_exists constant pls_integer := -2260;
-- ORA-02275: such a referential constraint already exists in the table
c_foreign_key_already_exists constant pls_integer := -2275;
-- ORA-23292: The constraint does not exist
c_constraint_does_not_exist constant pls_integer := -23292;
c_ignore_sqlcodes_constraint_ddl constant t_ignore_sqlcode_tab := t_ignore_sqlcode_tab(c_constraint_already_exists, c_primary_key_already_exists, c_foreign_key_already_exists, c_constraint_does_not_exist);

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

procedure ddl_execution_settings
( p_ddl_lock_timeout in pls_integer default 60 -- alter session set ddl_lock_timeout = p_ddl_lock_timeout;
, p_dry_run in boolean default false -- Must commands be execute or just shown via dbms_output?
);
/**
Change DDL execution settings.
**/

procedure column_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY or DROP
, p_table_name in user_tab_columns.table_name%type -- The table name
, p_column_name in user_tab_columns.column_name%type -- The column name
, p_extra in varchar2 default null -- To add after the column name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_column_ddl -- SQL codes to ignore
);
/**
Issues a 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' ' || p_column_name || ' ' || p_extra
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

procedure constraint_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY, RENAME or DROP
, p_table_name in user_constraints.table_name%type -- The table name
, p_constraint_name in user_constraints.constraint_name%type -- The constraint name
, p_constraint_type in user_constraints.constraint_type%type default null -- The constraint type (used when you RENAME or DROP a constraint containing the wildcard %)
, p_extra in varchar2 default null -- To add after the constraint name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default c_ignore_sqlcodes_constraint_ddl -- SQL codes to ignore
);
/**
Issues a 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || p_constraint_name || ' ' || p_extra
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
b. p_table_name is null: p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra
**/

$if cfg_pkg.c_testing $then

--%suitepath(CFG)
--%suite

--%beforeall
procedure ut_setup;

--%afterall
procedure ut_teardown;

--%test
procedure ut_table_ddl;

$end

end cfg_install_ddl_pkg;
/

