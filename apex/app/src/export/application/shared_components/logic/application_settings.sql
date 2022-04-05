prompt --application/shared_components/logic/application_settings
begin
--   Manifest
--     APPLICATION SETTINGS: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>94022060007722025
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_app_setting(
 p_id=>wwv_flow_api.id(48469174356698770)
,p_name=>'ACCESS_CONTROL_SCOPE'
,p_value=>'ACL_ONLY'
,p_is_required=>'N'
,p_valid_values=>'ACL_ONLY, ALL_USERS'
,p_on_upgrade_keep_value=>true
,p_required_patch=>wwv_flow_api.id(48469522283698800)
,p_comments=>'The default access level given to authenticated users who are not in the access control list'
);
wwv_flow_api.component_end;
end;
/
