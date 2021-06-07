prompt --application/shared_components/user_interface/lovs/lov_determine_datatype
begin
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(65177840871101570)
,p_lov_name=>'LOV_DETERMINE_DATATYPE'
,p_lov_query=>'.'||wwv_flow_api.id(65177840871101570)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(65177564530101546)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Datatype string, length max'
,p_lov_return_value=>'0'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(65177147786101545)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Datatype exact, length min'
,p_lov_return_value=>'1'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(65176741131101544)
,p_lov_disp_sequence=>3
,p_lov_disp_value=>'Datatype exact, length max'
,p_lov_return_value=>'2'
);
end;
/
