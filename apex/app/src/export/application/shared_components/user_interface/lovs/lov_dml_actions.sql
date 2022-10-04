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
,p_default_id_offset=>151930114232313867
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list_of_values(
 p_id=>wwv_flow_api.id(59217749697825803)
,p_lov_name=>'LOV_DML_ACTIONS'
,p_lov_query=>'.'||wwv_flow_api.id(59217749697825803)||'.'
,p_location=>'STATIC'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(59217991932825811)
,p_lov_disp_sequence=>1
,p_lov_disp_value=>'Insert'
,p_lov_return_value=>'I'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(59218449745825812)
,p_lov_disp_sequence=>2
,p_lov_disp_value=>'Replace (empty first and insert next)'
,p_lov_return_value=>'R'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(59218849882825812)
,p_lov_disp_sequence=>3
,p_lov_disp_value=>'Update'
,p_lov_return_value=>'U'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(59219173972825812)
,p_lov_disp_sequence=>4
,p_lov_disp_value=>'Merge (update or insert)'
,p_lov_return_value=>'M'
);
wwv_flow_api.create_static_lov_data(
 p_id=>wwv_flow_api.id(59219574916825812)
,p_lov_disp_sequence=>5
,p_lov_disp_value=>'Delete'
,p_lov_return_value=>'D'
);
wwv_flow_api.component_end;
end;
/
