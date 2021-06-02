prompt --application/shared_components/security/authorizations/administration_rights
begin
wwv_flow_api.create_security_scheme(
 p_id=>wwv_flow_api.id(18423627818600248)
,p_name=>'Administration Rights'
,p_scheme_type=>'NATIVE_FUNCTION_BODY'
,p_attribute_01=>'return oracle_tools.ui_user_management_pkg.has_role(sys.odcivarchar2list(''OT Administrators'')) != 0;'
,p_error_message=>'You do not have access to this data'
,p_reference_id=>107313449081880162
,p_caching=>'BY_USER_BY_PAGE_VIEW'
);
end;
/
