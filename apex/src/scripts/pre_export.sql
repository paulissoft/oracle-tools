-- &1 userid
-- &2 workspace name
-- &3 application id
-- &4 update language mapping (optional, defaults to 0 - false)
-- &5 seed and publish (optional, defaults to 1 - true)

prompt (pre_export.sql)

whenever sqlerror exit failure
whenever oserror exit failure

@@ connect.sql '&1'

prompt @@ define_parameters.sql
@@ define_parameters.sql

prompt @@ pre_export_no_connect.sql '&2' '&3' '&4' '&5'
@@ pre_export_no_connect.sql '&2' '&3' '&4' '&5'

undefine 1 2 3 4 5
