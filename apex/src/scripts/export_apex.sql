-- &1 workspace name
-- &2 application id
-- &3 directory of this script

set serveroutput on size unlimited format trunc

prompt (export_apex.sql)

whenever oserror exit failure
whenever sqlerror exit failure

set define on verify off feedback off

define workspace_name = '&1'
define application_id = '&2'
define script_dir = '&3'

/*
prompt @@ pre_export.sql &&workspace_name &&application_id
@@ pre_export.sql &&workspace_name &&application_id
*/

-- ORA-08177: can't serialize access for this transaction
-- https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=103654445502564&parent=EXTERNAL_SEARCH&sourceId=PROBLEM&id=2893264.1&_afrWindowMode=0&_adf.ctrl-state=eb5o4ic74_4
alter session set nls_numeric_characters = '.,';

declare
  l_files apex_t_export_files;
  l_max_tries constant pls_integer := 3;
begin
  <<try_loop>>
  for i_try in 1..l_max_tries
  loop
    begin
      commit;

      l_files := apex_export.get_application
                 ( p_application_id => &&application_id
                 , p_split => true
                 , p_with_ir_public_reports => true
                 , p_with_ir_private_reports => true
                 , p_with_translations => true
                 , p_with_original_ids => true
                 );
      exit try_loop; -- OK           
    exception
      when others
      then
        if i_try = l_max_tries then raise; end if;
        
        dbms_output.put_line('=== error try ' || i_try || ' ===');
        dbms_output.put_line(sqlerrm);
    end;             
  end loop try_loop;

  delete
  from    oracle_tools.tmp_export_apex;
  
  for i_idx in 1..l_files.count
  loop
    insert into oracle_tools.tmp_export_apex
    ( id
    , name
    , contents
    )
    values
    ( i_idx
    , l_files(i_idx).name
    , l_files(i_idx).contents
    );
  end loop;
end;
/


set heading off pagesize 0 flush off termout off trimspool on

column rm new_value rm

select  case when '&_EDITOR' = 'notepad' then 'del' else 'rm' end as rm
from    dual;

set termout on

define export_apex_output_files_sql = tmp_export_apex_output_files.sql

spool &export_apex_output_files_sql

-- print id and directory
with src as (
  select  src.id
  ,       substr(src.name, 1, instr(src.name, '/', -1)-1) as dir
  from    oracle_tools.tmp_export_apex src
)
select  '@&script_dir/export_apex_output_file.sql ' || src.id || ' ' || src.dir as cmd
from    src
order by
        src.dir -- so no hierachy needs to be created and we can use mkdir both on Unix and Windows
,       src.id;

spool off

prompt (start) @ &export_apex_output_files_sql
@ &export_apex_output_files_sql
prompt (end)   @ &export_apex_output_files_sql

rem host &rm &export_apex_output_files_sql

undefine 1 2 3 workspace_name application_id script_dir

exit sql.sqlcode
