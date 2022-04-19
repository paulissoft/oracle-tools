prompt --application/shared_components/logic/application_computations/fsp_language_preference
begin
--   Manifest
--     APPLICATION COMPUTATION: FSP_LANGUAGE_PREFERENCE
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_computation(
 p_id=>wwv_flow_api.id(58007455162719480)
,p_computation_sequence=>10
,p_computation_item=>'FSP_LANGUAGE_PREFERENCE'
,p_computation_point=>'AFTER_SUBMIT'
,p_computation_type=>'ITEM_VALUE'
,p_computation_processed=>'REPLACE_EXISTING'
,p_computation=>'REQUEST'
,p_compute_when=>'en,fr'
,p_compute_when_type=>'REQUEST_IN_CONDITION'
);
wwv_flow_api.component_end;
end;
/
