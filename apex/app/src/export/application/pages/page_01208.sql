prompt --application/pages/page_01208
begin
--   Manifest
--     PAGE: 01208
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>73921019511620241
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page(
 p_id=>1208
,p_user_interface_id=>wwv_flow_api.id(49557922988366350)
,p_name=>'Wizards'
,p_step_title=>'Wizards'
,p_reload_on_submit=>'A'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'ON'
,p_page_css_classes=>'dm-Page dm-Page--center'
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_help_text=>'No help is available for this page.'
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210607030029'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(240087821403165707)
,p_plug_name=>'Load File Wizard'
,p_region_name=>'wizard_list'
,p_region_template_options=>'#DEFAULT#:t-ContentBlock--h2'
,p_plug_template=>wwv_flow_api.id(49635018797366421)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>The <strong>Load File Wizard</strong> is a modal dialog progress list used to upload a file and save it into a table (or view).</p>',
'<p class="dm-Hero-steps">Use page <strong>2</strong> as the page to redirect to.</p>',
'<p>You can use it from another application (in the same workspace) in which case you should set Session Sharing Type to Workspace Sharing (Shared Components -> Authentication Schemes -> Application Express Authentication) to prevent a new login when '
||'redirecting, see also <a href="http://www.grassroots-oracle.com/2019/01/oracle-apex-application-session-sharing.html" target="_blank">Session Sharing</a>.</p>',
''))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(2120199029617928116)
,p_plug_name=>'Example 1'
,p_parent_plug_id=>wwv_flow_api.id(240087821403165707)
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(49653466587366429)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(2120198779452928113)
,p_plug_name=>'Load File Wizard Progress Bar'
,p_parent_plug_id=>wwv_flow_api.id(2120199029617928116)
,p_region_template_options=>'#DEFAULT#:t-ContentBlock--padded:t-ContentBlock--h3:t-ContentBlock--lightBG:margin-top-md:margin-bottom-sm'
,p_component_template_options=>'#DEFAULT#:t-WizardSteps--displayLabels'
,p_plug_template=>wwv_flow_api.id(49635018797366421)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_list_id=>wwv_flow_api.id(49521957934347272)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(49599408472366397)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(240088812175165708)
,p_plug_name=>'About'
,p_region_template_options=>'#DEFAULT#:t-ContentBlock--h2'
,p_plug_template=>wwv_flow_api.id(49635018797366421)
,p_plug_display_sequence=>1
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_source=>'<p>Wizards can be very useful in simplifying complex flows into smaller, more manageable steps.  This page describes the Load File Wizard.</p>'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(240089337072165709)
,p_plug_name=>'Breadcrumb'
,p_region_template_options=>'#DEFAULT#:t-BreadcrumbRegion--useBreadcrumbTitle'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(49622732735366410)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_menu_id=>wwv_flow_api.id(49678786676366464)
,p_plug_source_type=>'NATIVE_BREADCRUMB'
,p_menu_template_id=>wwv_flow_api.id(49579009694366383)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(240089840915165710)
,p_plug_name=>'Region Display Selector'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(49653656580366429)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'REGION_POSITION_01'
,p_plug_source_type=>'NATIVE_DISPLAY_SELECTOR'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'STANDARD'
,p_attribute_02=>'Y'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(47594924527318020)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(240087821403165707)
,p_button_name=>'LoadFile'
,p_button_action=>'REDIRECT_PAGE'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(49579811713366384)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Load File'
,p_button_position=>'BELOW_BOX'
,p_button_redirect_url=>'f?p=&APP_ID.:2:&SESSION.::&DEBUG.:RP,::'
,p_icon_css_classes=>'fa-upload'
,p_security_scheme=>'MUST_NOT_BE_PUBLIC_USER'
);
wwv_flow_api.component_end;
end;
/
