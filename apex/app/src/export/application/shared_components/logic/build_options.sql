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
,p_default_id_offset=>94022060007722025
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(48470058713729276)
,p_build_option_name=>'USE_APEX_GROUPS'
,p_build_option_status=>'INCLUDE'
,p_build_option_comment=>'Use standard Apex Users and Groups for authorization.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(48469522283698800)
,p_build_option_name=>'Feature: Access Control'
,p_build_option_status=>'EXCLUDE'
,p_feature_identifier=>'APPLICATION_ACCESS_CONTROL'
,p_build_option_comment=>'Incorporate role based user authentication within your application and manage username mappings to application roles.'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(33008304811600306)
,p_build_option_name=>'Not used'
,p_build_option_status=>'EXCLUDE'
,p_build_option_comment=>'An unused item'
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(31065774309654993)
,p_build_option_name=>'Feature: Theme Style Selection'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_THEME_STYLE_SELECTION'
,p_build_option_comment=>'Allow administrators to select a default color scheme (theme style) for the application. Administrators can also choose to allow end users to choose their own theme style. '
);
wwv_flow_api.create_build_option(
 p_id=>wwv_flow_api.id(31065719873654993)
,p_build_option_name=>'Feature: About Page'
,p_build_option_status=>'INCLUDE'
,p_feature_identifier=>'APPLICATION_ABOUT_PAGE'
,p_build_option_comment=>'About this application page.'
);
wwv_flow_api.component_end;
end;
/
