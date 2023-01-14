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
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page(
 p_id=>1
,p_user_interface_id=>wwv_flow_api.id(18420547356600209)
,p_name=>'Home'
,p_alias=>'HOME'
,p_step_title=>'PATO'
,p_autocomplete_on_off=>'OFF'
,p_page_template_options=>'#DEFAULT#'
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210511124335'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(18582894256035688)
,p_plug_name=>'Navigation'
,p_region_template_options=>'#DEFAULT#:margin-bottom-lg'
,p_component_template_options=>'#DEFAULT#:t-Cards--featured force-fa-lg:t-Cards--displayIcons:t-Cards--3cols:t-Cards--hideBody:t-Cards--animColorFill'
,p_plug_template=>wwv_flow_api.id(18324813764600130)
,p_plug_display_sequence=>30
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_list_id=>wwv_flow_api.id(20311687578427798)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(18389201559600167)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(1970645346310029930)
,p_plug_name=>'PATO'
,p_icon_css_classes=>'fa-dynamic-content'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(18333257185600133)
,p_plug_display_sequence=>20
,p_plug_display_point=>'BODY'
,p_plug_item_display_point=>'BELOW'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<span class="dm-Logo app-sample-universal-theme"></span>',
'<h1><span>Oracle Application Express </span>PATO</h1>',
'<p class="margin-top-lg">This is a set of tools including:',
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
