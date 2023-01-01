CREATE OR REPLACE PACKAGE "DATA_PARTITIONING_PKG" authid current_user is

/**

A package for operations on (soon to be) partitioned tables.

This includes:
- DDL to alter a table into a partitioned one
- drop 

This package has AUTHID CURRENT_USER so that it can be used by 
any schema issueing partitioning ddl.

**/

subtype t_value is varchar2(4000 char);

type t_range_rec is record
( partition_name all_tab_partitions.partition_name%type
, partition_position all_tab_partitions.partition_position%type
, lwb_incl t_value
, upb_excl t_value
);

type t_range_tab is table of t_range_rec;

function alter_table_range_partitioning
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_partition_by in varchar2 default null
, p_interval in varchar2 default null
, p_subpartition_by in varchar2 default null
, p_partition_clause in varchar2 default null
, p_online in boolean default true
)
return varchar2;

/**
 
Return the DDL for turning a non-partitioned table into a range (interval) partitioned one.

The table must be in the USERs schema.

It returns something like:

```sql
ALTER TABLE <p_table> MODIFY [ <p_partition_by> ] [ <p_interval> ] [ <p_subpartition_by> ] [ (<p_partition_clause>) ] [ ONLINE ]
```

**/

function show_partitions_range
( p_table in varchar2  -- checked by ORACLE_TOOLS.DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
)
return t_range_tab
pipelined;

/**
 
Return the partitions and their range as stored in USER_TAB_PARTITIONS.

The high_value in that dictionary view is a long like TIMESTAMP' 2021-08-26 00:00:00'.

The table must be in the USERs schema.

**/

end data_partitioning_pkg;
/

