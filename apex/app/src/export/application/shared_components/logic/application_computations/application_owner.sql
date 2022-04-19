prompt --application/shared_components/logic/application_computations/application_owner
begin
--   Manifest
--     APPLICATION COMPUTATION: APPLICATION_OWNER
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>107828709909037496
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(44026913231991006)
,p_computation_sequence=>10
,p_computation_item=>'APPLICATION_OWNER'
,p_computation_point=>'AFTER_LOGIN'
,p_computation_type=>'QUERY'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  a.owner',
'from    apex_applications a',
'where   a.application_id = to_number(:APP_ID)'))
);
wwv_flow_api.component_end;
end;
/
