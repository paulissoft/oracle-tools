prompt --application/shared_components/user_interface/lovs/lov_excel_sheets
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(26158557667099729)
,p_lov_name=>'LOV_EXCEL_SHEETS'
,p_lov_query=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  t.column_value as d',
',       t.column_value as r',
'from    apex_application_temp_files f',
',       table(ext_load_file_pkg.get_sheets(f.blob_content)) t',
'where   f.name = :P3_FILE',
'and     f.mime_type != ''text/csv'''))
,p_source_type=>'LEGACY_SQL'
,p_location=>'LOCAL'
);
end;
/
