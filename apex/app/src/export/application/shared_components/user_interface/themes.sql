prompt --application/shared_components/user_interface/themes
begin
--   Manifest
--     THEME: 138
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_theme(
 p_id=>wwv_flow_api.id(18400799948600186)
,p_theme_id=>42
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_ui_type_name=>'DESKTOP'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_reference_id=>4070917134413059350
,p_is_locked=>false
,p_default_page_template=>wwv_flow_api.id(18318598262600123)
,p_default_dialog_template=>wwv_flow_api.id(18303604239600116)
,p_error_template=>wwv_flow_api.id(18305116921600118)
,p_printer_friendly_template=>wwv_flow_api.id(18318598262600123)
,p_breadcrumb_display_point=>'REGION_POSITION_01'
,p_sidebar_display_point=>'REGION_POSITION_02'
,p_login_template=>wwv_flow_api.id(18305116921600118)
,p_default_button_template=>wwv_flow_api.id(18398658631600175)
,p_default_region_template=>wwv_flow_api.id(18346340098600141)
,p_default_chart_template=>wwv_flow_api.id(18346340098600141)
,p_default_form_template=>wwv_flow_api.id(18346340098600141)
,p_default_reportr_template=>wwv_flow_api.id(18346340098600141)
,p_default_tabform_template=>wwv_flow_api.id(18346340098600141)
,p_default_wizard_template=>wwv_flow_api.id(18346340098600141)
,p_default_menur_template=>wwv_flow_api.id(18355737609600149)
,p_default_listr_template=>wwv_flow_api.id(18346340098600141)
,p_default_irr_template=>wwv_flow_api.id(18345208626600140)
,p_default_report_template=>wwv_flow_api.id(18368814450600156)
,p_default_label_template=>wwv_flow_api.id(18397825820600171)
,p_default_menu_template=>wwv_flow_api.id(18399460650600176)
,p_default_calendar_template=>wwv_flow_api.id(18399514721600178)
,p_default_list_template=>wwv_flow_api.id(18396199092600170)
,p_default_nav_list_template=>wwv_flow_api.id(18388006144600166)
,p_default_top_nav_list_temp=>wwv_flow_api.id(18388006144600166)
,p_default_side_nav_list_temp=>wwv_flow_api.id(18387598762600165)
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>wwv_flow_api.id(18336791840600134)
,p_default_dialogr_template=>wwv_flow_api.id(18324813764600130)
,p_default_option_label=>wwv_flow_api.id(18397825820600171)
,p_default_required_label=>wwv_flow_api.id(18397888814600173)
,p_default_page_transition=>'NONE'
,p_default_popup_transition=>'NONE'
,p_default_navbar_list_template=>wwv_flow_api.id(18389051277600167)
,p_file_prefix => nvl(wwv_flow_application_install.get_static_theme_file_prefix(42),'#IMAGE_PREFIX#themes/theme_42/1.2/')
,p_files_version=>62
,p_icon_library=>'FONTAPEX'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#IMAGE_PREFIX#libraries/apex/#MIN_DIRECTORY#widget.stickyWidget#MIN#.js?v=#APEX_VERSION#',
'#THEME_IMAGES#js/theme42#MIN#.js?v=#APEX_VERSION#'))
,p_css_file_urls=>'#THEME_IMAGES#css/Core#MIN#.css?v=#APEX_VERSION#'
);
wwv_flow_api.component_end;
end;
/
