prompt --application/shared_components/user_interface/lovs/lov_dml_actions
begin
--   Manifest
--     LOV_DML_ACTIONS
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>139229780191799327
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(80012030493973524)
,p_lov_name=>'LOV_DML_ACTIONS'
,p_lov_query=>'.'||wwv_flow_api.id(80012030493973524)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(80011788258973516)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Insert'
,p_lov_return_value=>'I'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(80011330445973515)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Replace (empty first and insert next)'
,p_lov_return_value=>'R'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(80010930308973515)
,p_lov_disp_sequence=>3
,p_lov_disp_value=>'Update'
,p_lov_return_value=>'U'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(80010606218973515)
,p_lov_disp_sequence=>4
,p_lov_disp_value=>'Merge (update or insert)'
,p_lov_return_value=>'M'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(80010205274973515)
,p_lov_disp_sequence=>5
,p_lov_disp_value=>'Delete'
,p_lov_return_value=>'D'
);
wwv_flow_api.component_end;
end;
/
