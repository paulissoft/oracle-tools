CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_REPLICATE_UTIL" AUTHID CURRENT_USER IS

/**

This package contains utilities to replicate tables between schemas (from the same or a different database).

On the same database it will be implemented by a synonym (that you can use in a user defined view).

On a different database it will be implemented by a materialized view on a prebuilt table (CTAS) having the same indexes.

**/

procedure replicate_table
( p_table_name in varchar2 -- the table name
, p_table_owner in varchar2 -- the table owner
, p_column_list in varchar2 -- the colums separated by a comma
, p_where_clause in varchar2 default null -- the where clause (without WHERE)
, p_db_link in varchar2 default null -- database link: the table may reside on a separate database
, p_create_or_replace in varchar2 default null -- or CREATE/REPLACE
);

/**

Replicate a table to the schema of the current user.

The table owner must be different (or the database link not empty).

On a local database the target schema (the current logged in user) will (re-create) a synonym on the source table. The synonym name will be the same as the source table name.

On a remote database the target schema (the current logged in user) will (re-)create a table based on the source table plus column list and a materialized view on this prebuilt table. Indexes on the source table will be (re-)created too (if the columns match). The target table name (and materialized name) will be the same as the source table name.

The values for parameter **p_create_or_replace**:
- null: target may or may NOT exist
- CREATE: target must NOT exist
- REPLACE target must exist

When this action has been executed successfully, the user can create a view based on the synonym/materialized view. And privileges to other users.

**/

end pkg_replicate_util;
/

