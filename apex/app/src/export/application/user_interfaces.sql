prompt --application/user_interfaces
begin
--   Manifest
--     USER INTERFACES: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>107828709909037496
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_user_interface(
 p_id=>wwv_flow_api.id(37869754848289457)
,p_ui_type_name=>'DESKTOP'
,p_display_name=>'Desktop'
,p_display_seq=>10
,p_use_auto_detect=>false
,p_is_default=>true
,p_theme_id=>42
,p_home_url=>'f?p=&APP_ID.:1:&SESSION.'
,p_login_url=>'f?p=&APP_ID.:LOGIN_DESKTOP:&SESSION.'
,p_theme_style_by_user_pref=>false
,p_built_with_love=>false
,p_global_page_id=>0
,p_navigation_list_id=>wwv_flow_api.id(37749387892289345)
,p_navigation_list_position=>'SIDE'
,p_navigation_list_template_id=>wwv_flow_api.id(37836806254289413)
,p_nav_list_template_options=>'#DEFAULT#'
,p_css_file_urls=>'#APP_IMAGES#app-icon.css?version=#APP_VERSION#'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#APP_IMAGES#loglevel.min.js',
'#APP_IMAGES#loglevel-plugin-prefix.min.js',
'#APP_IMAGES#oracleTools.js'))
,p_nav_bar_type=>'LIST'
,p_nav_bar_list_id=>wwv_flow_api.id(37869404242289455)
,p_nav_bar_list_template_id=>wwv_flow_api.id(37838258769289415)
,p_nav_bar_template_options=>'#DEFAULT#'
);
wwv_flow_api.component_end;
end;
/
