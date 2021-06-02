prompt --application/pages/page_03000
begin
wwv_flow_api.create_page(
 p_id=>3000
,p_user_interface_id=>wwv_flow_api.id(47397907220621635)
,p_name=>'Components'
,p_step_title=>'Components'
,p_warn_on_unsaved_changes=>'N'
,p_autocomplete_on_off=>'OFF'
,p_page_template_options=>'#DEFAULT#'
,p_page_is_public_y_n=>'Y'
,p_help_text=>'No help is available for this page.'
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20200420100529'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(45500844318701552)
,p_plug_name=>'Breadcrumb'
,p_region_template_options=>'#DEFAULT#:t-BreadcrumbRegion--useBreadcrumbTitle'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(47462716967621695)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_menu_id=>wwv_flow_api.id(47518770908621749)
,p_plug_source_type=>'NATIVE_BREADCRUMB'
,p_menu_template_id=>wwv_flow_api.id(47418993926621668)
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(526825928087211038)
,p_plug_name=>'Components'
,p_icon_css_classes=>'fa-lg fa-shapes u-color-15'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(47485197391621711)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(812713950059102716)
,p_plug_name=>'Component Types'
,p_region_template_options=>'#DEFAULT#'
,p_component_template_options=>'#DEFAULT#:u-colors:t-Cards--featured t-Cards--block force-fa-lg:t-Cards--displayIcons:t-Cards--4cols:t-Cards--hideBody:t-Cards--animColorFill'
,p_plug_template=>wwv_flow_api.id(47493640812621714)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_list_id=>wwv_flow_api.id(45500271011701545)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(47429253017621677)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
end;
/
