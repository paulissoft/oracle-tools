prompt --application/shared_components/logic/application_items/fsp_language_preference
begin
--   Manifest
--     APPLICATION ITEM: FSP_LANGUAGE_PREFERENCE
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>94022060007722025
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(43018424607724289)
,p_name=>'FSP_LANGUAGE_PREFERENCE'
,p_scope=>'GLOBAL'
,p_protection_level=>'S'
);
wwv_flow_api.component_end;
end;
/
