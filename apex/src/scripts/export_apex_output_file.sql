set define on

define id = &1
define dir = &2

variable id number
variable name varchar2(1000)
variable contents clob

execute :id := &id

begin
  select  name
  ,       contents
  into    :name
  ,       :contents
  from    oracle_tools.tmp_export_apex
  where   id = :id;          
end;
/

set feedback off echo off heading off flush off termout off trimspool on
set long 100000000 longchunksize 32767

col name new_val name

select :name name from sys.dual;
/*
host mkdir &dir || echo &dir already exists
spool &name.
print contents
spool off
*/
set termout on
prompt (export_apex_output_file.sql) id: &id, dir: &dir, name: &name

undefine id dir
