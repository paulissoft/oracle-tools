prompt --application/shared_components/user_interface/lovs/lov_eol
begin
--   Manifest
--     LOV_EOL
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>87221669669135900
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(50349425813912835)
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
wwv_flow_api.component_end;
end;
/
