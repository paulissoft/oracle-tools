prompt --application/shared_components/user_interface/lovs/lov_quote_characters
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(56990578462173954)
,p_lov_name=>'LOV_QUOTE_CHARACTERS'
,p_lov_query=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select ''" (double quote)'' as d,',
'       rawtohex(utl_raw.cast_to_raw(''"'')) as r',
'  from dual',
'union all',
'select '''''' (single quote)'' as d,',
'       rawtohex(utl_raw.cast_to_raw('''''''')) as r',
'  from dual',
''))
,p_source_type=>'LEGACY_SQL'
,p_location=>'LOCAL'
);
end;
/
