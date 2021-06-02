prompt --application/shared_components/user_interface/lovs/lov_eol
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(24229356132168317)
,p_lov_name=>'LOV_EOL'
,p_lov_query=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select ''CRLF (Windows)'' as d,',
'       rawtohex(chr(13)||chr(10)) as r',
'  from dual',
'union all',
'select ''LF (Unix/Linux)'' as d,',
'       rawtohex(chr(10)) as r',
'  from dual',
'union all',
'select ''CR (Mac)'' as d,',
'       rawtohex(chr(13)) as r',
'  from dual',
''))
,p_source_type=>'LEGACY_SQL'
,p_location=>'LOCAL'
);
end;
/
