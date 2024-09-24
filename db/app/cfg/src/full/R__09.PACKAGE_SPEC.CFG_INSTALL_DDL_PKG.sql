CREATE OR REPLACE PACKAGE "CFG_INSTALL_DDL_PKG" AUTHID CURRENT_USER
is 

/**
This package defines functions and procedures used by Flyway increments (or more in general by DDL change operations).
**/

-- ORA-01430: column being added already exists in table
c_column_added_already_exists constant pls_integer := -1430;

-- ORA-00955: name is already used by an existing object
c_table_created_already_exists constant pls_integer := -955;

-- ORA-02264: name already used by an existing constraint
c_constraint_added_already_exists constant pls_integer := -2264;

type t_ignore_sqlcode_tab is table of pls_integer;

procedure column_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY or DROP
, p_table_name in user_tab_columns.table_name%type -- The table name
, p_column_name in user_tab_columns.column_name%type -- The column name
, p_extra in varchar2 default null -- To add after the column name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab(c_column_added_already_exists) -- SQL codes to ignore
);
/**
Issues a 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' ' || p_column_name || ' ' || p_extra
**/

procedure table_ddl
( p_operation in varchar2 -- The operation: usually CREATE, ALTER or DROP
, p_table_name in user_tab_columns.table_name%type -- The table name
, p_extra in varchar2 default null -- To add after the table name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab(c_table_created_already_exists) -- SQL codes to ignore
);
/**
Issues a p_operation || ' TABLE ' || p_table_name || ' ' || p_extra
**/

procedure constraint_ddl
( p_operation in varchar2 -- The operation: usually ADD, MODIFY or DROP
, p_table_name in user_constraints.table_name%type -- The table name
, p_constraint_name in user_constraints.constraint_name%type -- The constraint name
, p_extra in varchar2 default null -- To add after the constraint name
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab(c_constraint_added_already_exists) -- SQL codes to ignore
);
/**
Issues a 'ALTER TABLE ' || p_table_name || ' ' || p_operation || ' CONSTRAINT ' || p_constraint_name || ' ' || p_extra
**/

procedure comment_ddl
( p_table_name in user_tab_columns.table_name%type -- The table name
, p_column_name in user_tab_columns.column_name%type default null -- The column name (empty for a table comment)
, p_comment in varchar2 default null -- The comment (empty to remove)
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab() -- default no SQL codes to ignore
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
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab() -- default no SQL codes to ignore
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
, p_ignore_sqlcode_tab in t_ignore_sqlcode_tab default t_ignore_sqlcode_tab() -- default no SQL codes to ignore
);
/**
Issues:
a. p_table_name is not null: p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra || ' ON ' || p_table_name || chr(10) || p_extra
b. p_table_name is null: p_operation || ' TRIGGER ' || p_trigger_name || ' ' || p_trigger_extra
**/

end cfg_install_ddl_pkg;
/

