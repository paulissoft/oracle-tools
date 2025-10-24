CREATE OR REPLACE PACKAGE "DATA_TABLE_MGMT_PKG" authid current_user is

/**

A package for operations on tables.

This includes:
- Rebuild indexes

This package has AUTHID CURRENT_USER so that it can be used by 
any schema issueing DDL.

**/

procedure rebuild_indexes
( p_table_owner in all_indexes.table_owner%type default sys_context('USERENV', 'CURRENT_SCHEMA')   -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_table_name in all_indexes.table_name%type default null     -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_index_name in all_indexes.index_name%type default null     -- checked by DATA_API_PKG.DBMS_ASSERT$SIMPLE_SQL_NAME()
, p_index_status in all_indexes.status%type default 'UNUSABLE' -- a wildcard status
);

/**

Rebuild indexes that match the criteria, i.e. issue the following DDL returned from this query:

```sql
select  'ALTER INDEX "' || i.index_name || '" REBUILD' as DDL
from    user_indexes i
where   ( p_table_owner is null or i.table_owner = p_table_owner )
and     ( p_table_name is null or i.table_name = p_table_name )
and     ( p_index_name is null or i.index_name = p_index_name )
and     i.status like p_index_status escape '\'
```

The index must be in the USERs schema.

**/
                           
end data_table_mgmt_pkg;
/

