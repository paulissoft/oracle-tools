CREATE OR REPLACE PACKAGE "DATA_PARTITIONING_PKG" authid current_user is

/**

A package for operations on (soon to be) partitioned tables.

This includes:
- DDL to alter a table into a partitioned one
- drop 

This package has AUTHID CURRENT_USER so that it can be used by 
any schema issueing partitioning ddl.

**/

function alter_table_range_partitioning
( p_table in varchar2  -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
, p_column in varchar2 -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
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


procedure drop_partition
( p_table in varchar2  -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
, p_column in varchar2 -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
, p_maximal_high_value_to_purge in varchar2
);

procedure drop_partition
( p_table in varchar2  -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
, p_column in varchar2 -- checked by DBMS_ASSERT.SIMPLE_SQL_NAME()
, p_last_day_to_purge in date
);

end data_partitioning_pkg;
/

