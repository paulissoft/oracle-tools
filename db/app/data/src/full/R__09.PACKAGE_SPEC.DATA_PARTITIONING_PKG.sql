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
, interval all_tab_partitions.interval%type -- YES for anchor partition in interval partitioned table (when ALL_PART_TABLES.INTERVAL is not null)
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

The HIGH_VALUE in that dictionary view is a LONG like:
- TIMESTAMP' 2021-08-26 00:00:00' (data type TIMESTAMP)
- TO_DATE(' 2021-04-01 00:00:00', 'SYYYY-MM-DD HH24:MI:SS', 'NLS_CALENDAR=GREGORIAN') (data type DATE)

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

function find_partitions_range
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_date in date -- the reference date to find the reference partition
, p_operator in varchar2 default '=' -- '<', '=' or '>'
)
return t_range_tab
pipelined;

/**
 
Find the partitions with respect to the reference date and operator:
- for operator '=' we return the partition where the reference date lies inside the range (lwb_incl <= p_reference_date < upb_excl, both ends may be null).
- for operator '<' we will return all partitions where the exclusive upper bound (may not be empty) is at most the reference date
- for operator '>' we will return all partitions where the inclusive lower bound (may not be empty) is greater than the reference date

**/

procedure create_new_partitions 
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_timestamp in timestamp -- create partitions where the last one created will includes this timestamp
, p_update_index_clauses in varchar2 default 'UPDATE GLOBAL INDEXES' -- can be empty or UPDATE GLOBAL INDEXES
, p_nr_days_per_partition in positiven default 1 -- the number of days per partition
);

/**
 
Create new range partitions until the reference timestamp lies inside the last created partition.

Only meant for a range partitioned table without an interval (ALL_PART_TABLES.PARTITIONING_TYPE = 'RANGE' and ALL_PART_TABLES.INTERVAL is null).

One of the statements to create a partition: 

```sql
ALTER TABLE "<p_table_owner>"."<p_table_name>" ADD PARTITION "<new partition>" VALUES LESS THAN (TIMESTAMP '<timestamp>') <p_update_index_clauses>
```

**/

procedure create_new_partitions 
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_date in date -- create partitions where the last one created will includes this date
, p_update_index_clauses in varchar2 default 'UPDATE GLOBAL INDEXES' -- can be empty or UPDATE GLOBAL INDEXES
, p_nr_days_per_partition in positiven default 1 -- the number of days per partition
);

/**
 
Create new range partitions until the reference date lies inside the last created partition.

Only meant for a range partitioned table without an interval (ALL_PART_TABLES.PARTITIONING_TYPE = 'RANGE' and ALL_PART_TABLES.INTERVAL is null).

One of the statements to create a partition: 

```sql
ALTER TABLE "<p_table_owner>"."<p_table_name>" ADD PARTITION "<new partition>" VALUES LESS THAN (TO_DATE('<date>', 'YYYY-MM-DD')) <p_update_index_clauses>
```

**/

procedure drop_old_partitions
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_timestamp in timestamp -- the reference timestamp to find the reference partition (that will NOT be dropped)
, p_update_index_clauses in varchar2 default 'UPDATE INDEXES' -- can be empty or UPDATE GLOBAL INDEXES as well
, p_backup in boolean default false -- if true, a backup table will be used for each exchanged partition, before the drop
);

/**
 
Drop (and optionally backup) partitions before the reference timestamp.

For a partitioned table with an interval (ALL_PART_TABLES.INTERVAL is not null) only the partitions with ALL_TAB_PARTITIONS.INTERVAL = 'YES' are dropped.
When there is not an interval defined for the table, there is no such restriction.

This query will be used to find the old partitions:

```sql
select  p.* 
from    table
        ( oracle_tools.data_partitioning_pkg.find_partitions_range
          ( p_table_owner
          , p_table_name
          , p_reference_timestamp
          , '<'
          )
        ) p
        cross join all_part_tables t
where   t.owner = p_table_owner
and     t.table_name = p_table_name
and     t.partitioning_type = 'RANGE'
and     (t.interval is null or p.interval = 'YES')
```

The statements to create a backup table and exchange the partition (when p_backup is true):

```sql
CREATE TABLE "<p_table_owner>"."<p_table_name>_<timestamp>_<partition>"
  TABLESPACE "<tablespace>"
  FOR EXCHANGE WITH TABLE "<p_table_owner>"."<p_table_name>";

ALTER TABLE "<p_table_owner>"."<p_table_name>"
  EXCHANGE PARTITION "<partition>"
  WITH TABLE "<p_table_owner>"."<p_table_name>_<timestamp>_<partition>"
  WITHOUT VALIDATION
  <p_update_index_clauses>;
```

where <timestamp> is the system date in 'yyyymmddhh24miss' format and <tablespace> the table space of the source table.

See also [Create Table for Exchange With a Partitioned Table in Oracle Database 12c Release 2 (12.2)](https://oracle-base.com/articles/12c/create-table-for-exchange-with-table-12cr2).

The statement to drop the partition (always executed since the exchange does not drop the old partition): 

```sql
ALTER TABLE "<p_table_owner>"."<p_table_name>" DROP PARTITION "<old partition>" <p_update_index_clauses>;
```

See also [Updating indexes with partition maintenance](https://connor-mcdonald.com/2017/09/20/updating-indexes-with-partition-maintenance/).

**/

procedure drop_old_partitions
( p_table_owner in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in varchar2 -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_reference_date in date -- the reference date to find the reference partition (that will NOT be dropped)
, p_update_index_clauses in varchar2 default 'UPDATE INDEXES' -- can be empty or UPDATE GLOBAL INDEXES as well
, p_backup in boolean default false -- if true, a backup table will be used for each exchanged partition, before the drop
);
/** See drop_old_partitions for TIMESTAMPs. */

end data_partitioning_pkg;
/

