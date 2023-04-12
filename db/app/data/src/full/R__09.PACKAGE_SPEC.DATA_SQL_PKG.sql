CREATE OR REPLACE PACKAGE "DATA_SQL_PKG" authid current_user is

-- c_column_value_is_anydata constant boolean := false; -- true;

-- SYS.STANDARD defines TIME_UNCONSTRAINED and TIME_TZ_UNCONSTRAINED but there is no anydata.Convert* function for it.
c_support_time constant boolean := false;

-- ORA-03001: unimplemented feature
e_unimplemented_feature exception;
pragma exception_init(e_unimplemented_feature, -3001);

/**
Use dynamic SQL to retrieve data as either scalars or arrays by using SYS.ANYDATA.
It is essentially created to enable SQL on a set of related tables, i.e. tables with a foreign key relation.

Only (scalar and array) types supported by DBMS_SQL and ANYDATA are supported by this package.

Scalar data types supported:

| SQL data type                     | Convert to anydata function | ANYDATA type                |
| :------------                     | :-------------------------- | :-----------                |
| CLOB                              |                             | SYS.CLOB                    |               
| BINARY_FLOAT                      |                             | SYS.BINARY_FLOAT            |
| BINARY_DOUBLE                     |                             | SYS.BINARY_DOUBLE           |
| BLOB                              |                             | SYS.BLOB                    |
| BFILE                             |                             | SYS.BFILE                   |
| DATE                              |                             | SYS.DATE                    |
| NUMBER                            |                             | SYS.NUMBER                  |
| UROWID                            |                             | SYS.UROWID                  |
| VARCHAR2                          |                             | SYS.VARCHAR2                |
| TIMESTAMP                         |                             | SYS.TIMESTAMP               |
| TIMESTAMP(6) WITH LOCAL TIME ZONE |                             | SYS.TIMESTAMP_WITH_LTZ      |
| TIMESTAMP(6) WITH TIME ZONE       |                             | SYS.TIMESTAMP_WITH_TIMEZONE |
| INTERVAL DAY(2) TO SECOND(6)      |                             | SYS.INTERVAL_DAY_SECOND     |
| INTERVAL YEAR(2) TO MONTH         |                             | SYS.INTERVAL_YEAR_MONTH     |

 
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
1. Please note that it is usually the anydata scalar type name with '_TABLE' as suffix but with some exceptions:
2. Not SYS.TIMESTAMP_WITH_TIMEZONE_TABLE
3. Not SYS.INTERVAL_DAY_SECOND_TABLE
4. Not SYS.INTERVAL_YEAR_MONTH_TABLE

In PL/SQL you replace SYS. by DBMS_SQL. (they are all defined there), so DBMS_SQL.CLOB_TABLE, DBMS_SQL.BINARY_FLOAT_TABLE and so on.
 
This package has AUTHID CURRENT_USER so that it can be used by 
any schema to which this package has been granted.

**/

subtype statement_t is varchar2(32767 byte); -- max length supported by dbms_sql.parse

type statement_tab_t is table of statement_t index by all_tab_columns.table_name%type;
/** Sometimes a parent or child table may have a selection not so simple as "select * from <table>". **/

type row_count_tab_t is table of natural index by all_tab_columns.table_name%type;
/** Input: specify the maximum row count to fetch for a table. Output: the number of rows retrieved / processed. **/

type column_value_t is record
( data_type all_tab_columns.data_type%type -- determines which field records are valid
, is_table boolean default false -- determines whether the scalar (FALSE) or array variant (TRUE) is valid

, clob$                clob
, clob$_table          dbms_sql.clob_table

, binary_float$        binary_float
, binary_float$_table  dbms_sql.binary_float_table

, binary_double$       binary_double
, binary_double$_table dbms_sql.binary_double_table

, blob$                blob
, blob$_table          dbms_sql.blob_table

, bfile$               bfile
, bfile$_table         dbms_sql.bfile_table

, date$                date
, date$_table          dbms_sql.date_table

, number$              number
, number$_table        dbms_sql.number_table

, urowid$              urowid
, urowid$_table        dbms_sql.urowid_table

, varchar2$            varchar2(4000 char)
, varchar2$_table      dbms_sql.varchar2_table

, timestamp$           timestamp
, timestamp$_table     dbms_sql.timestamp_table

, timestamp_ltz$       timestamp with local time zone
, timestamp_ltz$_table dbms_sql.timestamp_with_ltz_table

, timestamp_tz$        timestamp with time zone
, timestamp_tz$_table  dbms_sql.timestamp_with_time_zone_table 

, interval_ds$         interval day to second
, interval_ds$_table   dbms_sql.interval_day_to_second_table

, interval_ym$         interval year to month
, interval_ym$_table   dbms_sql.interval_year_to_month_table 
);


-- subtype anydata_t is sys.anydata;
subtype anydata_t is column_value_t;

type column_value_tab_t is table of anydata_t index by all_tab_columns.column_name%type;
type table_column_value_tab_t is table of column_value_tab_t index by all_tab_columns.table_name%type;

-- public routines

function empty_anydata
return anydata_t;

function empty_column_value_tab
return column_value_tab_t;

procedure do
( p_operation in varchar2 -- (S)elect, (M)erge or (D)elete
, p_table_name in varchar2 -- the table name
, p_bind_variable_tab in column_value_tab_t default empty_column_value_tab -- only when an entry exists that table column will be used in the query or DML
, p_statement in statement_t default null -- if null it will default to 'select * from <table>' for a (S)elect
, p_order_by in varchar2 default null -- to be added after the (default) query (without ORDER BY)
, p_owner in varchar2 default user -- the owner of the table
, p_row_count in out nocopy natural
, p_column_value_tab in out nocopy column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
);
/**
Perform SQL for a single table.

The input value for p_row_count determines how and how much rows is retrieved for a query (select):
- when 1: select just a single row (and raise exceptions no_data_found / too_many_rows when no or more than 1 row is fetched) and store them in scalars
- when null: unlimited number of fetches and store them in arrays (even though at most 1 row may be fetched)
- when greater than 1: fetch at most this amount of rows and store them in arrays (even though at most 1 row may be fetched)
**/

function empty_statement_tab
return statement_tab_t;

procedure do
( p_operation in varchar2 -- (S)elect, (M)erge or (D)elete
, p_parent_table_name in varchar2 -- we must start with this
, p_table_bind_variable_tab in table_column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
, p_statement_tab in statement_tab_t default empty_statement_tab -- per table a query (if any): if none or null it will default to 'select * from <table>' for a (S)elect
, p_order_by_tab in statement_tab_t default empty_statement_tab -- per table an order by (if any)
, p_owner in varchar2 default user -- the owner of the table(s)
, p_row_count_tab in out nocopy row_count_tab_t -- per table a max row count (if any) on input
, p_table_column_value_tab in out nocopy table_column_value_tab_t -- only when an entry exists that table column will be used in the query or DML
);
/**
Perform SQL for a set of related tables.
**/

type column_info_rec_t is record
( owner all_tab_columns.owner%type
, table_name all_tab_columns.table_name%type
, column_name all_tab_columns.column_name%type
, data_type all_tab_columns.data_type%type
, data_length all_tab_columns.data_length%type
, pk_key_position all_cons_columns.position%type
);

type column_info_tab_t is table of column_info_rec_t;

function get_column_info
( p_owner in all_tab_columns.owner%type
, p_table_name in all_tab_columns.table_name%type
, p_column_name_list in all_tab_columns.column_name%type default '%' -- comma separated list of column names (wildcards allowed)
)
return column_info_tab_t
pipelined;

function empty_clob_table
return dbms_sql.clob_table;

function empty_binary_float_table
return dbms_sql.binary_float_table;

function empty_binary_double_table
return dbms_sql.binary_double_table;

function empty_blob_table
return dbms_sql.blob_table;

function empty_bfile_table
return dbms_sql.bfile_table;

function empty_date_table
return dbms_sql.date_table;

function empty_number_table
return dbms_sql.number_table;

function empty_urowid_table
return dbms_sql.urowid_table;

function empty_varchar2_table
return dbms_sql.varchar2_table;

function empty_timestamp_table
return dbms_sql.timestamp_table;

function empty_timestamp_ltz_table
return dbms_sql.timestamp_with_ltz_table;

function empty_timestamp_tz_table
return dbms_sql.timestamp_with_time_zone_table;

function empty_interval_ds_table
return dbms_sql.interval_day_to_second_table;

function empty_interval_ym_table
return dbms_sql.interval_year_to_month_table;

procedure set_column_value
( p_data_type in all_tab_columns.data_type%type default null -- determines which field records are valid
, p_is_table in boolean default false -- determines whether the scalar (FALSE) or array variant (TRUE) is valid
, p_clob$ in clob default null
, p_clob$_table in dbms_sql.clob_table default empty_clob_table
, p_binary_float$ in binary_float default null
, p_binary_float$_table in dbms_sql.binary_float_table default empty_binary_float_table
, p_binary_double$ in binary_double default null
, p_binary_double$_table in dbms_sql.binary_double_table default empty_binary_double_table
, p_blob$ in blob default null
, p_blob$_table in dbms_sql.blob_table default empty_blob_table
, p_bfile$ in bfile default null
, p_bfile$_table in dbms_sql.bfile_table default empty_bfile_table
, p_date$ in date default null
, p_date$_table in dbms_sql.date_table default empty_date_table
, p_number$ in number default null
, p_number$_table in dbms_sql.number_table default empty_number_table
, p_urowid$ in urowid default null
, p_urowid$_table in dbms_sql.urowid_table default empty_urowid_table
, p_varchar2$ in varchar2 default null
, p_varchar2$_table in dbms_sql.varchar2_table default empty_varchar2_table
, p_timestamp$ in timestamp default null
, p_timestamp$_table in dbms_sql.timestamp_table default empty_timestamp_table
, p_timestamp_ltz$ in timestamp with local time zone default null
, p_timestamp_ltz$_table in dbms_sql.timestamp_with_ltz_table default empty_timestamp_ltz_table
, p_timestamp_tz$ in timestamp with time zone default null
, p_timestamp_tz$_table in dbms_sql.timestamp_with_time_zone_table default empty_timestamp_tz_table
, p_interval_ds$ in interval day to second default null
, p_interval_ds$_table in dbms_sql.interval_day_to_second_table default empty_interval_ds_table
, p_interval_ym$ in interval year to month default null
, p_interval_ym$_table in dbms_sql.interval_year_to_month_table default empty_interval_ym_table
, p_column_value out nocopy column_value_t
);

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
procedure ut_do_dept;

--%test
procedure ut_do_emp_dept;

--%test
procedure ut_check_types;

$end

end data_sql_pkg;
/

