prompt --application/shared_components/user_interface/lovs/lov_determine_datatype
begin
--   Manifest
--     LOV_DETERMINE_DATATYPE
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>84978882401008962
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(2800629473864989)
,p_lov_name=>'LOV_DETERMINE_DATATYPE'
,p_lov_query=>'.'||wwv_flow_api.id(2800629473864989)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(2800905814865013)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Datatype string, length max'
,p_lov_return_value=>'0'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(2801322558865014)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Datatype exact, length min'
,p_lov_return_value=>'1'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(2801729213865015)
,p_lov_disp_sequence=>3
,p_lov_disp_value=>'Datatype exact, length max'
,p_lov_return_value=>'2'
);
wwv_flow_api.component_end;
end;
/
