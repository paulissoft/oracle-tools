CREATE OR REPLACE PACKAGE "DATA_PARTITIONING_PKG" authid current_user is

/**

A package for operations on (soon to be) partitioned tables.

This includes:
- DDL to alter a table into a partitioned one
- Show all partitions of a range partitioned table
- Find partitions of a range partitioned table
- Drop old partitions

This package has AUTHID CURRENT_USER so that it can be used by 
any schema issueing partitioning ddl.

**/

subtype t_value is varchar2(4000 char);

/**

A subtype for ALL_TAB_PARTITIONS.HIGH_VALUE that is a LONG.

**/

type t_range_rec is record
( partition_name all_tab_partitions.partition_name%type
, partition_position all_tab_partitions.partition_position%type
, interval all_tab_partitions.interval%type -- YES for anchor partition
, lwb_incl t_value
, upb_excl t_value
);

/**

The record information returned by various pipelined functions.

**/

type t_range_tab is table of t_range_rec;

/**

The table information returned by various pipelined functions.

**/

function alter_table_range_partitioning
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_partition_by in varchar2 default null -- PARTITION BY <p_partition_by> (if not NULL)
, p_interval in varchar2 default null -- INTERVAL <p_interval> (if not NULL)
, p_subpartition_by in varchar2 default null -- SUBPARTITION BY <p_subpartition_by> (if not NULL)
, p_partition_clause in varchar2 default null -- describes how partitions are created
, p_online in boolean default true -- ONLINE (if TRUE)
, p_update_indexes in varchar2 default null -- UPDATE INDEXES <p_update_indexes> (if not NULL)
)
return varchar2;

/**
 
Return the DDL for turning a non-partitioned table into a range (interval) partitioned one.

It returns something like:

```sql
ALTER TABLE "<p_table_owner>"."<p_table_name>" MODIFY
[ PARTITION BY <p_partition_by> ]
[ INTERVAL <p_interval> ]
[ SUBPARTITION BY <p_subpartition_by> ]
[ <p_partition_clause> ]
[ ONLINE ]
[ UPDATE INDEXES <p_update_indexes> ]
```

See also [Converting a Non-Partitioned Table to a Partitioned Table](https://docs.oracle.com/en/database/oracle/oracle-database/12.2/vldbg/evolve-nopartition-table.html#GUID-5FDB7D59-DD05-40E4-8AB4-AF82EA0D0FE5).

**/

function show_partitions_range
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2  -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
)
return t_range_tab
pipelined;

/**
 
Return the partitions and their range as stored in ALL_TAB_PARTITIONS.

The HIGH_VALUE in that dictionary view is a LONG like TIMESTAMP' 2021-08-26 00:00:00'.

**/

function find_partitions_range
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_timestamp in timestamp -- the reference timestamp to find the reference partition
, p_operator in varchar2 default '=' -- '<', '=' or '>'
)
return t_range_tab
pipelined;

/**
 
Find the partitions with respect to the reference timestamp and operator:
- for operator '=' we return the partition where the reference timestamp lies inside the range (lwb_incl <= p_reference_timestamp < upb_excl, both ends may be null).
- for operator '<' we will return all partitions where the exclusive upper bound (may not be empty) is at most the reference timestamp
- for operator '>' we will return all partitions where the inclusive lower bound (may not be empty) is greater than the reference timestamp

**/

procedure drop_old_partitions 
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_timestamp in timestamp -- the reference timestamp to find the reference partition (that will NOT be dropped)
, p_update_index_clauses in varchar2 default 'UPDATE INDEXES' -- can be empty or UPDATE GLOBAL INDEXES as well
);

/**
 
Drop interval partitions before the reference timestamp.

This query will be used to find the old partitions:

```sql
select  t.* 
from    table
        ( oracle_tools.data_partitioning_pkg.find_partitions_range
          ( p_table_name
          , p_reference_timestamp
          , '<'
          )
        ) t
where   t.interval = 'YES'
```

The statement to drop: 

```sql
ALTER TABLE <p_table_name> DROP PARTITION <old partition> <p_update_index_clauses>
```

See also [Updating indexes with partition maintenance](https://connor-mcdonald.com/2017/09/20/updating-indexes-with-partition-maintenance/).

**/
                           
end data_partitioning_pkg;
/

