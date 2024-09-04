CREATE OR REPLACE PACKAGE "ORACLE_TOOLS"."PKG_REPLICATE_UTIL" AUTHID CURRENT_USER IS

/**

This package contains utilities to replicate tables between schemas (from the same or a different database).

On the same database it will be implemented by a synonym (that you can use in a user defined view).

On a different database and when the target can be modified it will be an identical table but only for the columns specified. Indexes and constraints will be created if applicable.

On a different database and when the target can NOT be modified it will be an identical table but only for the columns specified. Then a materialized view will be created based on the prebuilt table. Indexes and constraints will be created if applicable.

**/

procedure replicate_table
( p_table_name in varchar2 -- the table name
, p_table_owner in varchar2 -- the table owner
, p_column_list in varchar2 -- the columns separated by a comma
, p_create_or_replace in varchar2 default null -- or CREATE/REPLACE
, p_db_link in varchar2 default null -- database link: the table may reside on a separate database
  -- parameters below only relevant when database link is not null
, p_where_clause in varchar2 default null -- the where clause (without WHERE)
, p_read_only in boolean default true -- is the target read only?
);

/**

Replicate a table to the schema of the current user.

The table owner must be different (or the database link not empty).

On a local database the target schema (the current logged in user) will (re-)create a synonym on the source table. The synonym name will be the same as the source table name.

On a remote database the target schema (the current logged in user) will (re-)create a table based on the source table and column list:
- when the target can be modified it will be just that: an identical table but only for the columns specified.
- when the target can NOT be modified a materialized view will be created based on the prebuilt table.
Indexes and constraints will be created if applicable.

When this action has been executed successfully, a view is (re-)created (suffix _V) based on the synonym/materialized view and the column list (plus rowid as row_id).

The values for parameter **p_create_or_replace**:
- null: target object(s) may or may NOT exist
- CREATE: target object(s) must NOT exist
- REPLACE target object(s) must exist

**/

procedure replicate_view
( p_view_name in varchar2 -- the view name
, p_view_owner in varchar2 -- the view owner
, p_column_list in varchar2 -- the columns separated by a comma
, p_create_or_replace in varchar2 default null -- or CREATE/REPLACE
, p_db_link in varchar2 default null -- database link: the view may reside on a separate database
);

/**

Replicate a view to the schema of the current user.

The view owner must be different (or the database link not empty).

On a local database the target schema (the current logged in user) will (re-)create a view based on the source view and column list.

On a remote database the target schema (the current logged in user) will (re-)create a materialized view based on the source view and column list.
The materialized view will be created based on a prebuilt table.

The values for parameter **p_create_or_replace**:
- null: target object(s) may or may NOT exist
- CREATE: target object(s) must NOT exist
- REPLACE target object(s) must exist

**/

end pkg_replicate_util;
/

