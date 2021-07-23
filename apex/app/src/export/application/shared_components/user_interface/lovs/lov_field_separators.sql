prompt --application/shared_components/user_interface/lovs/lov_field_separators
begin
--   Manifest
--     LOV_FIELD_SEPARATORS
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>71778820537478575
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(43666214879563619)
,p_lov_name=>'LOV_FIELD_SEPARATORS'
,p_lov_query=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select '', (comma)'' as d,',
'       rawtohex(utl_raw.cast_to_raw('','')) as r',
'  from dual',
'union all',
'select ''; (semi-colon)'' as d,',
'       rawtohex(utl_raw.cast_to_raw('';'')) as r',
'  from dual',
''))
,p_source_type=>'LEGACY_SQL'
,p_location=>'LOCAL'
);
wwv_flow_api.component_end;
end;
/
