CREATE OR REPLACE PACKAGE "DATA_PARTITIONING_PKG" authid current_user is

/**

A package for operations on (soon to be) partitioned tables.

This includes:
- DDL to alter a table into a partitioned one
- drop 

This package has AUTHID CURRENT_USER so that it can be used by 
any schema issueing partitioning ddl.

**/

subtype timestamp_tz is timestamp with time zone;
subtype timestamp_ltz is timestamp with local time zone;

subtype t_value is varchar2(4000 char);

type t_value_rec is record
( partition_name all_tab_partitions.partition_name%type
, value_lwb_incl t_value
, value_upb_excl t_value
);

type t_value_tab is table of t_value_rec;

function alter_table_range_partitioning
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_column in varchar2 -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_interval in varchar2 default null -- to undo the interval partitioning
, p_partition_clause in varchar2 default null -- when you just want to undo interval partitioning
, p_online in boolean default true
)
return varchar2;

/**
 
Return the DDL for turning a non-partitioned table into a range (interval) partitioned one.

The table must be in the USERs schema.

It returns something like:

```sql
ALTER TABLE <p_table> PARTITION BY RANGE (<p_column>) INTERVAL (<p_interval>) [ (<p_partition_clause>) ] [ ONLINE ]
```

**/

function show_partitions
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
)
return t_value_tab
pipelined;

/**
 
Return the partitions and their lowest and highest value as storedin USER_TAB_PARTITIONS.

The table must be in the USERs schema.

**/

end data_partitioning_pkg;
/

