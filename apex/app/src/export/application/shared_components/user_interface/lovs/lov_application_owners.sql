prompt --application/shared_components/user_interface/lovs/lov_application_owners
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(24106732723599076)
,p_lov_name=>'LOV_APPLICATION_OWNERS'
,p_lov_query=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  distinct',
'        a.owner as d',
',       a.owner as r',
'from    apex_applications a',
'where   a.workspace_id = to_number(SYS_CONTEXT(''APEX$SESSION'',''WORKSPACE_ID''))',
'order by',
'        case when a.owner = ''&APPLICATION_OWNER.'' then 0 else 1 end',
',       d'))
,p_source_type=>'LEGACY_SQL'
,p_location=>'LOCAL'
);
end;
/
