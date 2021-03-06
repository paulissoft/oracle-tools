prompt --application/pages/page_00001
begin
--   Manifest
--     PAGE: 00001
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>114929092615904275
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page(
 p_id=>1
,p_user_interface_id=>wwv_flow_api.id(69958955060748039)
,p_name=>'Home'
,p_alias=>'HOME'
,p_step_title=>'Oracle Tools'
,p_autocomplete_on_off=>'OFF'
,p_page_template_options=>'#DEFAULT#'
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210511124335'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(69796608161312560)
,p_plug_name=>'Navigation'
,p_region_template_options=>'#DEFAULT#:margin-bottom-lg'
,p_component_template_options=>'#DEFAULT#:t-Cards--featured force-fa-lg:t-Cards--displayIcons:t-Cards--3cols:t-Cards--hideBody:t-Cards--animColorFill'
,p_plug_template=>wwv_flow_api.id(70054688652748118)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_list_id=>wwv_flow_api.id(68067814838920450)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(69990300857748081)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(1358323705978456350)
,p_plug_name=>'Oracle Tools'
,p_icon_css_classes=>'fa-dynamic-content'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(70046245231748115)
,p_plug_display_sequence=>20
,p_plug_display_point=>'BODY'
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<span class="dm-Logo app-sample-universal-theme"></span>',
'<h1><span>Oracle Application Express </span>Oracle Tools</h1>',
'<p class="margin-top-lg">This is a set of Oracle Tools including:',
'<ul>',
'<li>the Load File Wizard</li>',
'</ul></p>'))
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.component_end;
end;
/
