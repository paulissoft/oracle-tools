prompt --application/shared_components/user_interface/lovs/lov_field_separators
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(24312255465402940)
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
end;
/
