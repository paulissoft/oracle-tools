prompt --application/shared_components/security/authorizations/administration_rights
begin
--   Manifest
--     SECURITY SCHEME: Administration Rights
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>151530112565241691
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_security_scheme(
 p_id=>wwv_flow_api.id(57173520562461290)
,p_name=>'Administration Rights'
,p_scheme_type=>'NATIVE_FUNCTION_BODY'
,p_attribute_01=>'return oracle_tools.ui_user_management_pkg.has_role(sys.odcivarchar2list(''OT Administrators'')) != 0;'
,p_error_message=>'You do not have access to this data'
,p_reference_id=>107313449081880162
,p_caching=>'BY_USER_BY_PAGE_VIEW'
);
wwv_flow_api.component_end;
end;
/
