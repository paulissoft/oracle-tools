CREATE OR REPLACE PACKAGE "DATA_SQL_PKG" authid current_user is

/**
Use dynamic SQL to retrieve data as either scalars or arrays by using SYS.ANYDATA.
It is essentially created to enable SQL on a set of related tables, i.e. tables with a foreign key relation.


Scalar data types supported:
- DATE
- NUMBER
- VARCHAR2(4000)

Array types supported:
- SYS.ODCIDATELIST
- SYS.ODCINUMBERLIST
- SYS.ODCIVARCHAR2LIST

This package has AUTHID CURRENT_USER so that it can be used by 
any schema to which this package has been granted.



**/

-- ORA-03001: unimplemented feature
e_unimplemented_feature exception;
pragma exception_init(e_unimplemented_feature, -3001);

type common_key_name_tab_t is table of all_tab_columns.column_name%type index by all_tab_columns.table_name%type;
/** Either the name of the primary key column of the parent table or the foreign key column name for a child table. **/

subtype statement_t is varchar2(32767 byte); -- max length supported by dbms_sql.parse

type query_tab_t is table of statement_t index by all_tab_columns.table_name%type;
/** Sometimes a parent or child table may have a selection not so simple as "select * from <table>". **/

type max_row_count_tab_t is table of positive index by all_tab_columns.table_name%type;
/** Specify the maximum row count to fetch for a table. **/

type column_value_tab_t is table of anydata index by all_tab_columns.column_name%type;
type table_column_value_tab_t is table of column_value_tab_t index by all_tab_columns.table_name%type;

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_table_name in varchar2 -- the table name
, p_column_name in varchar2 -- the column name to query
, p_column_value in anydata default null -- the column value to query
, p_query in statement_t default null -- if null it will default to 'select * from <table>'
, p_order_by in varchar2 default null -- to be added after the (default) query (without ORDER BY)
, p_owner in varchar2 default user -- the owner of the table
, p_max_row_count in positive default null
, p_column_value_tab in out nocopy column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
);
/**
Perform SQL for a single table.

The value for p_max_row_count determines how and how much rows is retrieved for a query (select):
- when 1: select just a single row (and raise exceptions no_data_found / too_many_rows when no or more than 1 row is fetched) and store them in scalars
- when null: unlimited number of fetches and store them in arrays (even though at most 1 row may be fetched)
- when greater than 1: fetch at most this amount of rows and store them in arrays (even though at most 1 row may be fetched)
**/

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_common_key_name_tab in common_key_name_tab_t -- per table the common key column name
, p_common_key_value in anydata -- tables are related by this common key value
, p_query_tab in query_tab_t -- per table a query: if null it will default to 'select * from <table>'
, p_order_by_tab in query_tab_t -- per table an order by
, p_owner in varchar2 default user -- the owner of the table
, p_max_row_count_tab in max_row_count_tab_t
, p_table_column_value_tab in out nocopy table_column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
);
/**
Perform SQL for a set of related tables.
**/

$if cfg_pkg.c_testing $then

--%suitepath(DATA)
--%suite

--%beforeall
--%rollback(manual)
procedure ut_setup;

--%afterall
--%rollback(manual)
procedure ut_teardown;

--%test
procedure ut_do_emp;

--%test
--%disabled
procedure ut_do_dept;

--%test
--%disabled
procedure ut_do_emp_dept;

$end

end data_sql_pkg;
/

