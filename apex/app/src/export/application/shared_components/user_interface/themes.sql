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
,p_default_id_offset=>139229780191799327
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_theme(
 p_id=>wwv_flow_api.id(82079087499338099)
,p_theme_id=>42
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_ui_type_name=>'DESKTOP'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_reference_id=>4070917134413059350
,p_is_locked=>false
,p_default_page_template=>wwv_flow_api.id(82161289185338162)
,p_default_dialog_template=>wwv_flow_api.id(82176283208338169)
,p_error_template=>wwv_flow_api.id(82174770526338167)
,p_printer_friendly_template=>wwv_flow_api.id(82161289185338162)
,p_breadcrumb_display_point=>'REGION_POSITION_01'
,p_sidebar_display_point=>'REGION_POSITION_02'
,p_login_template=>wwv_flow_api.id(82174770526338167)
,p_default_button_template=>wwv_flow_api.id(82081228816338110)
,p_default_region_template=>wwv_flow_api.id(82133547349338144)
,p_default_chart_template=>wwv_flow_api.id(82133547349338144)
,p_default_form_template=>wwv_flow_api.id(82133547349338144)
,p_default_reportr_template=>wwv_flow_api.id(82133547349338144)
,p_default_tabform_template=>wwv_flow_api.id(82133547349338144)
,p_default_wizard_template=>wwv_flow_api.id(82133547349338144)
,p_default_menur_template=>wwv_flow_api.id(82124149838338136)
,p_default_listr_template=>wwv_flow_api.id(82133547349338144)
,p_default_irr_template=>wwv_flow_api.id(82134678821338145)
,p_default_report_template=>wwv_flow_api.id(82111072997338129)
,p_default_label_template=>wwv_flow_api.id(82082061627338114)
,p_default_menu_template=>wwv_flow_api.id(82080426797338109)
,p_default_calendar_template=>wwv_flow_api.id(82080372726338107)
,p_default_list_template=>wwv_flow_api.id(82083688355338115)
,p_default_nav_list_template=>wwv_flow_api.id(82091881303338119)
,p_default_top_nav_list_temp=>wwv_flow_api.id(82091881303338119)
,p_default_side_nav_list_temp=>wwv_flow_api.id(82092288685338120)
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>wwv_flow_api.id(82143095607338151)
,p_default_dialogr_template=>wwv_flow_api.id(82155073683338155)
,p_default_option_label=>wwv_flow_api.id(82082061627338114)
,p_default_required_label=>wwv_flow_api.id(82081998633338112)
,p_default_page_transition=>'NONE'
,p_default_popup_transition=>'NONE'
,p_default_navbar_list_template=>wwv_flow_api.id(82090836170338118)
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
