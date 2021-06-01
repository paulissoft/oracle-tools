prompt --application/shared_components/logic/application_processes/display_file
begin
wwv_flow_api.create_flow_process(
 p_id=>wwv_flow_api.id(47329736253541658)
,p_process_sequence=>1
,p_process_point=>'ON_DEMAND'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'DISPLAY_FILE'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'  l_file_id constant number := to_number(:FILE_ID);',
'begin',
'  for c1 in (select *',
'               from apex_application_temp_files',
'              where id = l_file_id) ',
'  loop',
'    sys.htp.init;',
'    sys.owa_util.mime_header( c1.mime_type, FALSE );',
'    sys.htp.p(''Content-length: '' || sys.dbms_lob.getlength( c1.blob_content));',
'    sys.htp.p(''Content-Disposition: inline; filename="'' || c1.filename || ''"'' );',
'    sys.htp.p(''Cache-Control: max-age=3600'');  -- tell the browser to cache for one hour, adjust as necessary',
'    sys.owa_util.http_header_close;',
'    sys.wpg_docload.download_file( c1.blob_content );',
'',
'    apex_application.stop_apex_engine;',
'  end loop;',
'exception',
'  when others',
'  then',
'    raise_application_error(-20000, ''file id: "'' || :file_id || ''"'', true);',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_security_scheme=>'MUST_NOT_BE_PUBLIC_USER'
);
end;
/
