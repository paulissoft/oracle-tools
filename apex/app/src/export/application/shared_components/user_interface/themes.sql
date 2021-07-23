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
,p_default_id_offset=>71778820537478575
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_theme(
 p_id=>wwv_flow_api.id(49577670396366373)
,p_theme_id=>42
,p_theme_name=>'Universal Theme'
,p_theme_internal_name=>'UNIVERSAL_THEME'
,p_ui_type_name=>'DESKTOP'
,p_navigation_type=>'L'
,p_nav_bar_type=>'LIST'
,p_reference_id=>4070917134413059350
,p_is_locked=>false
,p_default_page_template=>wwv_flow_api.id(49659872082366436)
,p_default_dialog_template=>wwv_flow_api.id(49674866105366443)
,p_error_template=>wwv_flow_api.id(49673353423366441)
,p_printer_friendly_template=>wwv_flow_api.id(49659872082366436)
,p_breadcrumb_display_point=>'REGION_POSITION_01'
,p_sidebar_display_point=>'REGION_POSITION_02'
,p_login_template=>wwv_flow_api.id(49673353423366441)
,p_default_button_template=>wwv_flow_api.id(49579811713366384)
,p_default_region_template=>wwv_flow_api.id(49632130246366418)
,p_default_chart_template=>wwv_flow_api.id(49632130246366418)
,p_default_form_template=>wwv_flow_api.id(49632130246366418)
,p_default_reportr_template=>wwv_flow_api.id(49632130246366418)
,p_default_tabform_template=>wwv_flow_api.id(49632130246366418)
,p_default_wizard_template=>wwv_flow_api.id(49632130246366418)
,p_default_menur_template=>wwv_flow_api.id(49622732735366410)
,p_default_listr_template=>wwv_flow_api.id(49632130246366418)
,p_default_irr_template=>wwv_flow_api.id(49633261718366419)
,p_default_report_template=>wwv_flow_api.id(49609655894366403)
,p_default_label_template=>wwv_flow_api.id(49580644524366388)
,p_default_menu_template=>wwv_flow_api.id(49579009694366383)
,p_default_calendar_template=>wwv_flow_api.id(49578955623366381)
,p_default_list_template=>wwv_flow_api.id(49582271252366389)
,p_default_nav_list_template=>wwv_flow_api.id(49590464200366393)
,p_default_top_nav_list_temp=>wwv_flow_api.id(49590464200366393)
,p_default_side_nav_list_temp=>wwv_flow_api.id(49590871582366394)
,p_default_nav_list_position=>'SIDE'
,p_default_dialogbtnr_template=>wwv_flow_api.id(49641678504366425)
,p_default_dialogr_template=>wwv_flow_api.id(49653656580366429)
,p_default_option_label=>wwv_flow_api.id(49580644524366388)
,p_default_required_label=>wwv_flow_api.id(49580581530366386)
,p_default_page_transition=>'NONE'
,p_default_popup_transition=>'NONE'
,p_default_navbar_list_template=>wwv_flow_api.id(49589419067366392)
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
