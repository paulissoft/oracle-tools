prompt --application/shared_components/logic/build_options
begin
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(47395622426621599)
,p_build_option_name=>'Feature: About Page'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_ABOUT_PAGE'
,p_build_option_comment=>'About this application page.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(47395567990621599)
,p_build_option_name=>'Feature: Theme Style Selection'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_THEME_STYLE_SELECTION'
,p_build_option_comment=>'Allow administrators to select a default color scheme (theme style) for the application. Administrators can also choose to allow end users to choose their own theme style. '
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(45453037488676286)
,p_build_option_name=>'Not used'
,p_build_option_status=>'EXCLUDE'
,p_build_option_comment=>'An unused item'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(29991820016577792)
,p_build_option_name=>'Feature: Access Control'
,p_build_option_status=>'EXCLUDE'
,p_feature_identifier=>'APPLICATION_ACCESS_CONTROL'
,p_build_option_comment=>'Incorporate role based user authentication within your application and manage username mappings to application roles.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(29991283586547316)
,p_build_option_name=>'USE_APEX_GROUPS'
,p_build_option_status=>'INCLUDE'
,p_build_option_comment=>'Use standard Apex Users and Groups for authorization.'
);
end;
/
