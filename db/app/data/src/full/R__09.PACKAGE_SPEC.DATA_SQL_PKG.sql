CREATE OR REPLACE PACKAGE "DATA_SQL_PKG" authid current_user is

-- SYS.STANDARD defines TIME_UNCONSTRAINED and TIME_TZ_UNCONSTRAINED but there is no anydata.Convert* function for it.
c_support_time constant boolean := false;

-- use SYS.ODCINUMBERLIST and so on
c_use_odci constant boolean := false;

-- use bulk fetch?
c_use_bulk_fetch constant boolean := true;

/**
Use dynamic SQL to retrieve data as either scalars or arrays by using SYS.ANYDATA.
It is essentially created to enable SQL on a set of related tables, i.e. tables with a foreign key relation.

Only (scalar and array) types supported by DBMS_SQL and ANYDATA are supported by this package.

Scalar data types supported (from anydata.gettypename(), see 1 below for SQL type names):
- SYS.CLOB
- SYS.BINARY_FLOAT
- SYS.BINARY_DOUBLE
- SYS.BLOB
- SYS.BFILE
- SYS.DATE
- SYS.NUMBER
- SYS.UROWID
- SYS.VARCHAR2
- SYS.TIMESTAMP
- SYS.TIMESTAMP_WITH_LTZ      (see 2)
- SYS.TIMESTAMP_WITH_TIMEZONE (see 3)
- SYS.INTERVAL_DAY_SECOND     (see 4)
- SYS.INTERVAL_YEAR_MONTH     (see 5)

SQL type names:
1. In PL/SQL you use NORMALLY the type name without 'SYS.', hence CLOB, BINARY_FLOAT and so on but with some exceptions:
2. TIMESTAMP WITH LOCAL TIME ZONE
3. TIMESTAMP WITH LOCAL TIME ZONE
4. INTERVAL DAY TO SECOND
5. INTERVAL YEAR TO MONTH
 
Array types supported (see 1 below for PL/SQL type names):
- SYS.CLOB_TABLE
- SYS.BINARY_FLOAT_TABLE
- SYS.BINARY_DOUBLE_TABLE
- SYS.BLOB_TABLE
- SYS.BFILE_TABLE
- SYS.DATE_TABLE
- SYS.NUMBER_TABLE
- SYS.UROWID_TABLE
- SYS.VARCHAR2_TABLE
- SYS.TIMESTAMP_TABLE
- SYS.TIMESTAMP_WITH_LTZ_TABLE
- SYS.TIMESTAMP_WITH_TIME_ZONE_TABLE (see 2)
- SYS.INTERVAL_DAY_TO_SECOND_TABLE (see 3)
- SYS.INTERVAL_YEAR_TO_MONTH_TABLE (see 4)

PL/SQL type names (not supported in SQL!):
1. Please note that it is usually the scalar type name with '_TABLE' as suffix but with some exceptions:
2. Not SYS.TIMESTAMP_WITH_TIMEZONE_TABLE
3. Not SYS.INTERVAL_DAY_SECOND_TABLE
4. Not SYS.INTERVAL_YEAR_MONTH_TABLE

In PL/SQL you replace SYS. by DBMS_SQL. (they are all defined there), so DBMS_SQL.CLOB_TABLE, DBMS_SQL.BINARY_FLOAT_TABLE and so on.
 
This package has AUTHID CURRENT_USER so that it can be used by 
any schema to which this package has been granted.

**/

-- ORA-03001: unimplemented feature
e_unimplemented_feature exception;
pragma exception_init(e_unimplemented_feature, -3001);

type column_name_tab_t is table of all_tab_columns.column_name%type index by all_tab_columns.table_name%type;
/** Either the name of the primary key column of the parent table or the foreign key column name for a child table. **/

subtype statement_t is varchar2(32767 byte); -- max length supported by dbms_sql.parse

type statement_tab_t is table of statement_t index by all_tab_columns.table_name%type;
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
, p_statement in statement_t default null -- if null it will default to 'select * from <table>' for a (S)elect
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
function empty_column_name_tab
return column_name_tab_t;

function empty_statement_tab
return statement_tab_t;

function empty_max_row_count_tab
return max_row_count_tab_t;

procedure do
( p_operation in varchar2 -- (S)elect, (I)nsert, (U)pdate or (D)elete
, p_parent_table_name in varchar2
, p_common_key_name_tab in column_name_tab_t -- per table the common key column name
, p_common_key_value in anydata -- tables are related by this common key value
, p_statement_tab in statement_tab_t default empty_statement_tab -- per table a query (if any): if none or null it will default to 'select * from <table>' for a (S)elect
, p_order_by_tab in statement_tab_t default empty_statement_tab -- per table an order by (if any)
, p_owner in varchar2 default user -- the owner of the table(s)
, p_max_row_count_tab in max_row_count_tab_t default empty_max_row_count_tab -- per table a max row count (if any)
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

--%test
procedure ut_check_types;

$end

end data_sql_pkg;
/

