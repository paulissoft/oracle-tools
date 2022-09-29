prompt --application/shared_components/logic/build_options
begin
--   Manifest
--     BUILD OPTIONS: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(35827170990674528)
,p_build_option_name=>'USE_APEX_GROUPS'
,p_build_option_status=>'INCLUDE'
,p_build_option_comment=>'Use standard Apex Users and Groups for authorization.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(35826634560644052)
,p_build_option_name=>'Feature: Access Control'
,p_build_option_status=>'EXCLUDE'
,p_feature_identifier=>'APPLICATION_ACCESS_CONTROL'
,p_build_option_comment=>'Incorporate role based user authentication within your application and manage username mappings to application roles.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(20365417088545558)
,p_build_option_name=>'Not used'
,p_build_option_status=>'EXCLUDE'
,p_build_option_comment=>'An unused item'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(18422886586600245)
,p_build_option_name=>'Feature: Theme Style Selection'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_THEME_STYLE_SELECTION'
,p_build_option_comment=>'Allow administrators to select a default color scheme (theme style) for the application. Administrators can also choose to allow end users to choose their own theme style. '
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(18422832150600245)
,p_build_option_name=>'Feature: About Page'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_ABOUT_PAGE'
,p_build_option_comment=>'About this application page.'
);
wwv_flow_api.component_end;
end;
/
