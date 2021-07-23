prompt --application/shared_components/security/authorizations/reader_rights
begin
--   Manifest
--     SECURITY SCHEME: Reader Rights
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>71778820537478575
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_security_scheme(
 p_id=>wwv_flow_api.id(32153059120322542)
,p_name=>'Reader Rights'
,p_scheme_type=>'NATIVE_FUNCTION_BODY'
,p_attribute_01=>'return oracle_tools.ui_user_management_pkg.has_role(sys.odcivarchar2list(''OT Administrators'', ''OT Contributors'', ''OT Readers'')) != 0;'
,p_error_message=>'You are not authorized to view this application, either because you have not been granted access, or your account has been locked. Please contact the application administrator.'
,p_caching=>'BY_USER_BY_SESSION'
);
wwv_flow_api.component_end;
end;
/
