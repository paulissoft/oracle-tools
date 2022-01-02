-- &1 workspace name
-- &2 application id
-- &3 update language mapping (optional, defaults to 0 - false)
-- &4 seed and publish (optional, defaults to 1 - true)

prompt (pre_export.sql)

whenever sqlerror exit failure

set define on verify off feedback off

column update_language_mapping new_value 3 noprint

-- define 3 if undefined
select  '' as update_language_mapping
from    dual
where   0 = 1;

select  '0' as update_language_mapping
from    dual
where   'X&3' = 'X';

column update_language_mapping clear

column seed_and_publish new_value 4 noprint

-- define 4 if undefined
select  '' as seed_and_publish
from    dual
where   0 = 1;

select  '1' as seed_and_publish
from    dual
where   'X&4' = 'X';

column seed_and_publish clear

call ui_apex_synchronize.pre_export(upper('&&1'), to_number('&2'), to_number('&3') != 0, to_number('&4') != 0);

undefine 1 2
