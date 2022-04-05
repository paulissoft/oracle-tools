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
,p_default_id_offset=>80521331112734834
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_theme(
 p_id=>wwv_flow_api.id(24343349115253868)
,p_theme_id=>42
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_ui_type_name=>'DESKTOP'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_reference_id=>4070917134413059350
,p_is_locked=>false
,p_default_page_template=>wwv_flow_api.id(24261147429253805)
,p_default_dialog_template=>wwv_flow_api.id(24246153406253798)
,p_error_template=>wwv_flow_api.id(24247666088253800)
,p_printer_friendly_template=>wwv_flow_api.id(24261147429253805)
,p_breadcrumb_display_point=>'REGION_POSITION_01'
,p_sidebar_display_point=>'REGION_POSITION_02'
,p_login_template=>wwv_flow_api.id(24247666088253800)
,p_default_button_template=>wwv_flow_api.id(24341207798253857)
,p_default_region_template=>wwv_flow_api.id(24288889265253823)
,p_default_chart_template=>wwv_flow_api.id(24288889265253823)
,p_default_form_template=>wwv_flow_api.id(24288889265253823)
,p_default_reportr_template=>wwv_flow_api.id(24288889265253823)
,p_default_tabform_template=>wwv_flow_api.id(24288889265253823)
,p_default_wizard_template=>wwv_flow_api.id(24288889265253823)
,p_default_menur_template=>wwv_flow_api.id(24298286776253831)
,p_default_listr_template=>wwv_flow_api.id(24288889265253823)
,p_default_irr_template=>wwv_flow_api.id(24287757793253822)
,p_default_report_template=>wwv_flow_api.id(24311363617253838)
,p_default_label_template=>wwv_flow_api.id(24340374987253853)
,p_default_menu_template=>wwv_flow_api.id(24342009817253858)
,p_default_calendar_template=>wwv_flow_api.id(24342063888253860)
,p_default_list_template=>wwv_flow_api.id(24338748259253852)
,p_default_nav_list_template=>wwv_flow_api.id(24330555311253848)
,p_default_top_nav_list_temp=>wwv_flow_api.id(24330555311253848)
,p_default_side_nav_list_temp=>wwv_flow_api.id(24330147929253847)
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>wwv_flow_api.id(24279341007253816)
,p_default_dialogr_template=>wwv_flow_api.id(24267362931253812)
,p_default_option_label=>wwv_flow_api.id(24340374987253853)
,p_default_required_label=>wwv_flow_api.id(24340437981253855)
,p_default_page_transition=>'NONE'
,p_default_popup_transition=>'NONE'
,p_default_navbar_list_template=>wwv_flow_api.id(24331600444253849)
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
