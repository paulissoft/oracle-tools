CREATE OR REPLACE PACKAGE BODY "ORACLE_TOOLS"."PKG_REPLICATE_UTIL" IS

procedure replicate_table
( p_table_name in varchar2 -- the table name
, p_table_owner in varchar2 -- the table owner
, p_column_list in varchar2 -- the colums separated by a comma
, p_where_clause in varchar2 default null -- the where clause (without WHERE)
, p_db_link in varchar2 default null -- database link: the table may reside on a separate database
, p_create_or_replace in varchar2 default null -- or CREATE/REPLACE
)
is
  l_table_name all_tables.table_name%type;
  l_table_owner all_tables.owner%type;
  l_create_or_replace constant varchar(100) :=
    case
      when upper(p_create_or_replace) in ('CREATE', 'REPLACE')
      then upper(p_create_or_replace)
      else 'CREATE OR REPLACE'
    end;
begin

  case
    when p_db_link is null
    then
      l_table_name := oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_name, 'table name');
      l_table_owner := oracle_tools.data_api_pkg.dbms_assert$enquote_name(p_table_owner, 'table owner');
      
      execute immediate l_create_or_replace || ' SYNONYM ' || l_table_name || ' FOR ' || l_table_owner || '.' || l_table_name;
  end case;  
end replicate_table;

/**

Replicate a table to the schema of the current user.

The table owner must be different (or the database link not empty).

On a local database the target schema (the current logged in user) will (re-create) a synonym on the source table plus the privileges requested. Privileges are granted with the GRANT option so you can create views on the source table.

On a remote database the target schema (the current logged in user) will (re-)create a table based on the source table plus column list and a materialized view on this prebuilt table. Indexes on the source table will be (re-)created too (if the columns match).

The values for parameter **p_create_or_replace**:
- null: target may or may NOT exist
- CREATE: target must NOT exist
- REPLACE target must exist

**/

end pkg_replicate_util;
/

