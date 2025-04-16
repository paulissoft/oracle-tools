CREATE OR REPLACE PACKAGE BODY "UI_APEX_EXPORT_PKG" 
as

function get_application
( p_application_id          in number
, p_type                    in apex_export.t_export_type       default apex_export.c_type_application_source
, p_split                   in boolean_t                       default 0
, p_with_date               in boolean_t                       default 0
, p_with_ir_public_reports  in boolean_t                       default 0
, p_with_ir_private_reports in boolean_t                       default 0
, p_with_ir_notifications   in boolean_t                       default 0
, p_with_translations       in boolean_t                       default 0
, p_with_original_ids       in boolean_t                       default 0
, p_with_no_subscriptions   in boolean_t                       default 0
, p_with_comments           in boolean_t                       default 0
, p_with_supporting_objects in varchar2                        default null
, p_with_acl_assignments    in boolean_t                       default 0
, p_components              in apex_t_varchar2                 default null
, p_with_audit_info         in apex_export.t_audit_type        default null
)
return file_tab_t pipelined
is
/*
ORA-14552: cannot perform a DDL, commit or rollback inside a query or DML 
ORA-06512: at "ORACLE_TOOLS.UI_APEX_EXPORT_PKG", line 57
ORA-06512: at "APEX_240100.WWV_FLOW_SECURITY", line 2142
ORA-06512: at "APEX_240100.WWV_FLOW_EXPORT_API", line 197
ORA-01453: SET TRANSACTION must be first statement of transaction
ORA-06512: at "APEX_240100.WWV_FLOW_EXPORT_API", line 70
ORA-06512: at "ORACLE_TOOLS.UI_APEX_EXPORT_PKG", line 31
*/

  pragma autonomous_transaction;
  
  l_files apex_t_export_files;

  l_max_tries constant pls_integer := 3;
begin
  -- ORA-08177: can't serialize access for this transaction
  -- https://support.oracle.com/epmos/faces/DocumentDisplay?_afrLoop=103654445502564&parent=EXTERNAL_SEARCH&sourceId=PROBLEM&id=2893264.1&_afrWindowMode=0&_adf.ctrl-state=eb5o4ic74_4
  execute immediate q'[alter session set nls_numeric_characters = '.,']';

  <<try_loop>>
  for i_try in 1..l_max_tries
  loop
    begin
      l_files :=
        apex_export.get_application
        ( p_application_id => p_application_id
        , p_type => p_type
        , p_split => p_split != 0
        , p_with_date => p_with_date != 0
        , p_with_ir_public_reports => p_with_ir_public_reports != 0
        , p_with_ir_private_reports => p_with_ir_private_reports != 0
        , p_with_ir_notifications => p_with_ir_notifications != 0
        , p_with_translations => p_with_translations != 0
        , p_with_original_ids => p_with_original_ids != 0
        , p_with_no_subscriptions => p_with_no_subscriptions != 0
        , p_with_comments => p_with_comments != 0
        , p_with_supporting_objects => p_with_supporting_objects
        , p_with_acl_assignments => p_with_acl_assignments != 0
        , p_components => p_components
        , p_with_audit_info => p_with_audit_info
        );        
        
      exit try_loop; -- OK           
    exception
      when others
      then
        pipe row (to_clob('-- === error ' || i_try || ' ==='));
        pipe row (to_clob(sqlerrm));

        if i_try = l_max_tries then raise; end if;        
    end;             
  end loop try_loop;
  
  for i_idx in 1..l_files.count
  loop
    pipe row (to_clob('-- === file ' || to_char(i_idx, 'FM0000') || ': ' || l_files(i_idx).name || ' ==='));
    pipe row (l_files(i_idx).contents);
  end loop;

  commit;

  return; -- necessary for a pipelined function
end;

end ui_apex_export_pkg;
/

