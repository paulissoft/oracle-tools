prompt --application/shared_components/security/app_access_control/reader
begin
--   Manifest
--     ACL ROLE: Reader
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>73921019511620241
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_acl_role(
 p_id=>wwv_flow_api.id(32152625968322541)
,p_static_id=>'READER'
,p_name=>'Reader'
,p_description=>'Role assigned to application readers.'
);
wwv_flow_api.component_end;
end;
/
