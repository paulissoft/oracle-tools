prompt --application/shared_components/logic/application_computations/show_help
begin
--   Manifest
--     APPLICATION COMPUTATION: SHOW_HELP
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>87221669669135900
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(54058740201627849)
,p_computation_sequence=>10
,p_computation_item=>'SHOW_HELP'
,p_computation_point=>'ON_NEW_INSTANCE'
,p_computation_type=>'STATIC_ASSIGNMENT'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>'1'
,p_computation_comment=>'Show help region by default but use the collapsible template.'
);
wwv_flow_api.component_end;
end;
/
