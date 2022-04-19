prompt --application/shared_components/user_interface/lovs/lov_boolean
begin
--   Manifest
--     LOV_BOOLEAN
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(64025249859734175)
,p_lov_name=>'LOV_BOOLEAN'
,p_lov_query=>'.'||wwv_flow_api.id(64025249859734175)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(64025016515734155)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'No'
,p_lov_return_value=>'0'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(64024601739734154)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Yes'
,p_lov_return_value=>'1'
);
wwv_flow_api.component_end;
end;
/
