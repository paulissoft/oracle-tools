prompt --application/pages/page_00005
begin
--   Manifest
--     PAGE: 00005
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>94022060007722025
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page(
 p_id=>5
,p_user_interface_id=>wwv_flow_api.id(31063435079654957)
,p_name=>'Load Summary'
,p_page_mode=>'MODAL'
,p_step_title=>'Load Summary'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// See https://rimblas.com/blog/2015/08/enhancement-to-waitpopup-on-apex5/',
'',
'// variable for return function (add it to your "Function and Global Variable Declaration" field)',
'var $wP;',
'',
'var field_names = ["P5_DETERMINE_DATATYPE", "P5_NEW_TABLE"];',
'',
'function EnableItems () {',
'  for (let i = 0; i < field_names.length; i++) {',
'    apex.item(field_names[i]).enable()',
'  }',
'}',
'',
'function DisableItems () {',
'  for (let i = 0; i < field_names.length; i++) {',
'    apex.item(field_names[i]).disable()',
'  }',
'}'))
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var button = parent.$(''.ui-dialog-titlebar-close''); //get the button',
'button.hide(); //hide the button'))
,p_step_template=>wwv_flow_api.id(30948817668654866)
,p_page_template_options=>'#DEFAULT#:ui-dialog--stretch'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_dialog_height=>'800'
,p_dialog_width=>'1000'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'This is the fourth and final step of the wizard to upload a spreadsheet file into the database.',
'',
'Here a summary is shown.'))
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210607030430'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(73165649822238868)
,p_plug_name=>'Wizard Progress'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(30967701487654878)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_list_id=>wwv_flow_api.id(31099400133674035)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(31021949595654910)
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(73165486856238868)
,p_plug_name=>'Source'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(30989227821654889)
,p_plug_display_sequence=>10
,p_plug_grid_column_span=>7
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(31224100252090419)
,p_plug_name=>'Column Info'
,p_parent_plug_id=>wwv_flow_api.id(73165486856238868)
,p_region_template_options=>'#DEFAULT#'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(30988096349654888)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  t.seq_id',
',       t.excel_column_name as file_column',
',       t.header_row as table_column',
',       t.data_row',
',       nvl',
'        ( ( select  c.data_type ||',
'                    case',
'                      when c.data_precision is not null and nvl(c.data_scale,0)>0 then ''(''||c.data_precision||'',''||c.data_scale||'')''',
'                      when c.data_precision is not null and nvl(c.data_scale,0)=0 then ''(''||c.data_precision||'')''',
'                      when c.data_precision is null and c.data_scale is not null then ''(*,''||c.data_scale||'')''',
'                      when c.char_length>0 then ''(''||c.char_length|| case c.char_used when ''B'' then '' Byte'' when ''C'' then '' Char'' end||'')''',
'                    end',
'            from    all_tab_columns c',
'            where   c.owner = :P5_SCHEMA',
'            and     c.table_name = ltrim(rtrim(:P5_TABLE_VIEW, ''"''), ''"'')',
'            and     c.column_name = t.header_row',
'          )',
'        , t.data_type',
'        ) as data_type',
',       t.format_mask',
',       case t.in_key when 0 then ''N'' else ''Y'' end as in_key',
',       t.default_value',
'from    table(ext_load_file_pkg.display(:P5_FILE_ID)) t',
''))
,p_plug_source_type=>'NATIVE_IG'
,p_ajax_items_to_submit=>'P5_SCHEMA,P5_TABLE_VIEW,P5_FILE_ID'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31225078338090429)
,p_name=>'DEFAULT_VALUE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DEFAULT_VALUE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Default Value'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>90
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31225042431090428)
,p_name=>'IN_KEY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IN_KEY'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_YES_NO'
,p_heading=>'In Key'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>80
,p_value_alignment=>'CENTER'
,p_attribute_01=>'APPLICATION'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224898223090427)
,p_name=>'FORMAT_MASK'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FORMAT_MASK'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Format Mask'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>70
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224805939090426)
,p_name=>'DATA_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_TYPE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Data Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>60
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224654538090425)
,p_name=>'DATA_ROW'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_ROW'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Data Row'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>50
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224582300090424)
,p_name=>'TABLE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TABLE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Table Column (header)'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>40
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224472409090423)
,p_name=>'FILE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'File Column'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>30
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(31224358519090422)
,p_name=>'SEQ_ID'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'SEQ_ID'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>20
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(31224209004090420)
,p_internal_uid=>51265655109910734
,p_is_editable=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_max_row_count=>100000
,p_show_nulls_as=>'-'
,p_select_first_row=>true
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>false
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU'
,p_enable_save_public_report=>true
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>false
,p_download_formats=>null
,p_enable_mail_download=>true
,p_fixed_header=>'PAGE'
,p_show_icon_view=>false
,p_show_detail_view=>false
);
wwv_flow_api.create_ig_report(
 p_id=>wwv_flow_api.id(32720418577179927)
,p_interactive_grid_id=>wwv_flow_api.id(31224209004090420)
,p_static_id=>'297063'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_rows_per_page=>5
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(32720492129179928)
,p_report_id=>wwv_flow_api.id(32720418577179927)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32724999657179947)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>8
,p_column_id=>wwv_flow_api.id(31225078338090429)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32724532126179945)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(31225042431090428)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>60
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32724022847179944)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(31224898223090427)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32723527149179942)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(31224805939090426)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32722994427179941)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(31224654538090425)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32722522817179940)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(31224582300090424)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32722017998179938)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(31224472409090423)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>80
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(32721466862179936)
,p_view_id=>wwv_flow_api.id(32720492129179928)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(31224358519090422)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(73165399630238868)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(30979679563654882)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(31223174653090410)
,p_plug_name=>'Target'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(30989227821654889)
,p_plug_display_sequence=>20
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>5
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(31223359282090412)
,p_plug_name=>'Existing Table/View'
,p_parent_plug_id=>wwv_flow_api.id(31223174653090410)
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(30989227821654889)
,p_plug_display_sequence=>20
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_plug_display_when_condition=>'P5_NEW_TABLE'
,p_plug_display_when_cond2=>'0'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(31223283278090411)
,p_plug_name=>'New Table'
,p_parent_plug_id=>wwv_flow_api.id(31223174653090410)
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(30989227821654889)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_plug_display_condition_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_plug_display_when_condition=>'P5_NEW_TABLE'
,p_plug_display_when_cond2=>'0'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(32604777140819958)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(73165399630238868)
,p_button_name=>'CLOSE'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(31041546354654923)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Close'
,p_button_position=>'REGION_TEMPLATE_NEXT'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38275080667150282)
,p_name=>'P5_DATA_ROW_TILL'
,p_item_sequence=>150
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_prompt=>'Last Data Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_display_when=>'P5_CSV_FILE'
,p_display_when2=>'0'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The last data row to process where empty means all starting from the first data row.'
,p_attribute_01=>'1'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(37089907826637890)
,p_name=>'P5_HEADER_ROW_TILL'
,p_item_sequence=>130
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_item_default=>'1'
,p_prompt=>'Header Row Till'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(36980655662254613)
,p_name=>'P5_VIEW_NAME'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_prompt=>'View Name'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_colspan=>4
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(36980381124252416)
,p_name=>'P5_CSV_FILE'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(33114975698607203)
,p_name=>'P5_DETERMINE_DATATYPE'
,p_is_required=>true
,p_item_sequence=>160
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_item_default=>'2'
,p_prompt=>'Determine Data Type'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DETERMINE_DATATYPE'
,p_lov=>'.'||wwv_flow_api.id(77820728594156318)||'.'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32692087501557988)
,p_name=>'P5_OWNER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(31223283278090411)
,p_use_cache_before_default=>'NO'
,p_prompt=>'New table schema to load into'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32673728827459438)
,p_name=>'P5_NEW_TABLE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(31223174653090410)
,p_use_cache_before_default=>'NO'
,p_item_default=>'0'
,p_prompt=>'New table?'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'CUSTOM'
,p_attribute_02=>'1'
,p_attribute_03=>'Yes'
,p_attribute_04=>'0'
,p_attribute_05=>'No'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32672240294445140)
,p_name=>'P5_TABLE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(31223283278090411)
,p_prompt=>'New table to load into'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32609839256819970)
,p_name=>'P5_NR_ROWS'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(31223174653090410)
,p_prompt=>'Number of rows processed'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The number of rows processed which means for each action:',
'<ul>',
'    <li>Insert - the number of rows inserted</li>',
'    <li>Replace - the number of rows inserted (the number of rows deleted first is not shown)</li>',
'    <li>Update - the number of rows updated</li>',
'    <li>Merge - the number of rows updated or inserted</li>',
'    <li>Delete - the number of rows deleted</li>',
'</ul>'))
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32609437349819969)
,p_name=>'P5_ACTION'
,p_is_required=>true
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(31223174653090410)
,p_item_default=>'I'
,p_prompt=>'Action'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DML_ACTIONS'
,p_lov=>'.'||wwv_flow_api.id(33110744677019509)||'.'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_read_only_when_type=>'ALWAYS'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#:t-Form-fieldContainer--radioButtonGroup'
,p_lov_display_extra=>'NO'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32609018581819969)
,p_name=>'P5_TABLE_VIEW'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(31223359282090412)
,p_prompt=>'Table/View to load into'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32608638728819969)
,p_name=>'P5_SCHEMA'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(31223359282090412)
,p_prompt=>'Table/View schema to load into'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  distinct',
'        a.owner as d',
',       a.owner as r',
'from    apex_applications a',
'where   a.workspace_id = to_number(SYS_CONTEXT(''APEX$SESSION'',''WORKSPACE_ID''))',
'order by',
'        d'))
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32608238349819968)
,p_name=>'P5_DATA_ROW_FROM'
,p_item_sequence=>140
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_item_default=>'0'
,p_prompt=>'Data Row From'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32607774053819968)
,p_name=>'P5_HEADER_ROW_FROM'
,p_item_sequence=>120
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_item_default=>'1'
,p_prompt=>'Header Row From'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32607401438819968)
,p_name=>'P5_LAST_EXCEL_COLUMN_NAME'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_prompt=>'Last Column (A,B,...)'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>2
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32606972194819968)
,p_name=>'P5_SHEET_NAMES'
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_prompt=>'Sheet(s)'
,p_display_as=>'PLUGIN_BE.CTB.SELECT2'
,p_named_lov=>'LOV_EXCEL_SHEETS'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  t.column_value as d',
',       t.column_value as r',
'from    apex_application_temp_files f',
',       table(ext_load_file_pkg.get_sheets(f.blob_content)) t',
'where   f.name = :P3_FILE',
'and     f.mime_type != ''text/csv'''))
,p_lov_display_null=>'YES'
,p_begin_on_new_line=>'N'
,p_display_when=>'P5_CSV_FILE'
,p_display_when2=>'1'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_read_only_when_type=>'ALWAYS'
,p_field_template=>wwv_flow_api.id(31040992633654921)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'YES'
,p_attribute_01=>'MULTI'
,p_attribute_06=>'Y'
,p_attribute_08=>'CIC'
,p_attribute_10=>'800'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32606568912819968)
,p_name=>'P5_FILE_NAME'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_prompt=>'File'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>4
,p_field_template=>wwv_flow_api.id(31040713543654919)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(32606201009819964)
,p_name=>'P5_FILE_ID'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(73165486856238868)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(36876543721231629)
,p_name=>'Disable Switches'
,p_event_sequence=>10
,p_bind_type=>'bind'
,p_bind_event_type=>'ready'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(36876651903231630)
,p_event_id=>wwv_flow_api.id(36876543721231629)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'DisableItems();'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(36876777819231632)
,p_name=>'Enable Switches'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(32604777140819958)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(36876854992231633)
,p_event_id=>wwv_flow_api.id(36876777819231632)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'EnableItems();'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(36877030613231634)
,p_event_id=>wwv_flow_api.id(36876777819231632)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_01=>'CLOSE'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(32617061004820003)
,p_process_sequence=>30
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_CLOSE_WINDOW'
,p_process_name=>'Close Dialog'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_api.id(32604777140819958)
);
wwv_flow_api.component_end;
end;
/
