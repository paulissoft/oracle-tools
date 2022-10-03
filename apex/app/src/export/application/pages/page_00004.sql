prompt --application/pages/page_00004
begin
--   Manifest
--     PAGE: 00004
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>151930114232313867
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page(
 p_id=>4
,p_user_interface_id=>wwv_flow_api.id(57170440100461251)
,p_name=>'Load'
,p_page_mode=>'MODAL'
,p_step_title=>'Load'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'// See https://rimblas.com/blog/2015/08/enhancement-to-waitpopup-on-apex5/',
'',
'// variable for return function (add it to your "Function and Global Variable Declaration" field)',
'var $wP;',
'',
'function run_long_request (request, warnmsg) {',
'  if (!warnmsg || confirm(warnmsg)) {',
'    apex.submit({request:request,showWait:true});',
'  }',
'}'))
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var button = parent.$(''.ui-dialog-titlebar-close''); //get the button',
'',
'button.hide(); //hide the button',
'button = $(''#refresh''); //get the button',
'button.hide(); //hide the button',
''))
,p_step_template=>wwv_flow_api.id(57055822689461160)
,p_page_template_options=>'#DEFAULT#:ui-dialog--stretch'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_dialog_height=>'800'
,p_dialog_width=>'1000'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'This is the third step of the wizard to upload a spreadsheet file into the database.',
'',
'Here you can define properties for the source (file) and the target (database).',
'',
'The target may be an existing table/view (in one of the allowed database schemas) or a new table (in the application owner schema).',
'',
'When a new table is created, the following information in the source region is used to create it:',
'<ul>',
'    <li>Table Column (header)</li>',
'    <li>Data Type</li>',
'    <li>Key?</li>',
'</ul>',
'',
'When you press the Load button, this will be verified:',
'<ol>',
'    <li>No duplicates for source "Table Column (header)".</li>',
'    <li>Every source "Table Column (header)" must exactly match one target Table/View column.</li>',
'    <li>For an update, merge or delete there must be a key.</li>',
'</ol>'))
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210607032836'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57329818588896700)
,p_plug_name=>'Source'
,p_region_name=>'source'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(57096232842461183)
,p_plug_display_sequence=>10
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(56979926771611805)
,p_plug_name=>'Column Info'
,p_region_name=>'file'
,p_parent_plug_id=>wwv_flow_api.id(57329818588896700)
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--hiddenOverflow'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(57096232842461183)
,p_plug_display_sequence=>20
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  t.seq_id',
',       t.excel_column_name as file_column',
',       t.header_row as table_column',
',       t.data_row',
'/*',
',       nvl',
'        ( ( select  c.data_type ||',
'                    case',
'                      when c.data_precision is not null and nvl(c.data_scale,0)>0 then ''(''||c.data_precision||'',''||c.data_scale||'')''',
'                      when c.data_precision is not null and nvl(c.data_scale,0)=0 then ''(''||c.data_precision||'')''',
'                      when c.data_precision is null and c.data_scale is not null then ''(*,''||c.data_scale||'')''',
'                      when c.char_length>0 then ''(''||c.char_length|| case c.char_used when ''B'' then '' Byte'' when ''C'' then '' Char'' end||'')''',
'                    end',
'            from    all_tab_columns c',
'            where   c.owner = :P4_SCHEMA',
'            and     c.table_name = ltrim(rtrim(:P4_TABLE_VIEW, ''"''), ''"'')',
'            and     c.column_name = t.header_row',
'          )',
'        , t.data_type',
'        ) as data_type',
'*/',
',       t.data_type',
',       t.format_mask',
',       case t.in_key when 0 then ''N'' else ''Y'' end as in_key',
',       t.default_value',
',       ext_load_file_pkg.excel_column_name2number(t.excel_column_name) as file_column_order',
'from    table',
'        ( ext_load_file_pkg.display',
'          ( p_apex_file_id => :P4_FILE_ID',
'          )',
'        ) t'))
,p_plug_source_type=>'NATIVE_IG'
,p_ajax_items_to_submit=>'P4_FILE_ID,P4_SCHEMA,P4_TABLE_VIEW'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(103921640146902991)
,p_name=>'FILE_COLUMN_ORDER'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_COLUMN_ORDER'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'File Column Order'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>120
,p_value_alignment=>'RIGHT'
,p_attribute_03=>'right'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56981076064611817)
,p_name=>'APEX$ROW_SELECTOR'
,p_item_type=>'NATIVE_ROW_SELECTOR'
,p_display_sequence=>10
,p_attribute_01=>'Y'
,p_attribute_02=>'Y'
,p_attribute_03=>'N'
,p_enable_hide=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56981006608611816)
,p_name=>'APEX$ROW_ACTION'
,p_item_type=>'NATIVE_ROW_ACTION'
,p_display_sequence=>20
,p_enable_hide=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980883719611815)
,p_name=>'DEFAULT_VALUE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DEFAULT_VALUE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXTAREA'
,p_heading=>'Default Value'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>110
,p_value_alignment=>'LEFT'
,p_attribute_01=>'Y'
,p_attribute_02=>'N'
,p_attribute_03=>'N'
,p_attribute_04=>'BOTH'
,p_is_required=>false
,p_max_length=>16000
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980789708611814)
,p_name=>'IN_KEY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IN_KEY'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_YES_NO'
,p_heading=>'Key?'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>100
,p_value_alignment=>'CENTER'
,p_attribute_01=>'APPLICATION'
,p_is_required=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'LOV'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980668226611813)
,p_name=>'FORMAT_MASK'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FORMAT_MASK'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXTAREA'
,p_heading=>'Format Mask'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>90
,p_value_alignment=>'LEFT'
,p_attribute_01=>'Y'
,p_attribute_02=>'N'
,p_attribute_03=>'N'
,p_attribute_04=>'BOTH'
,p_is_required=>false
,p_max_length=>400
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_readonly_condition_type=>'VALUE_OF_ITEM_IN_CONDITION_NOT_IN_COLON_DELIMITED_LIST'
,p_readonly_condition=>'DATA_TYPE'
,p_readonly_condition2=>'DATE,TIMESTAMP'
,p_readonly_for_each_row=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980607634611812)
,p_name=>'DATA_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_TYPE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXTAREA'
,p_heading=>'Data Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>80
,p_value_alignment=>'LEFT'
,p_attribute_01=>'Y'
,p_attribute_02=>'N'
,p_attribute_03=>'N'
,p_attribute_04=>'BOTH'
,p_is_required=>false
,p_max_length=>400
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_lov_type=>'NONE'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_readonly_condition_type=>'ITEM_IS_NOT_NULL'
,p_readonly_condition=>'P4_TABLE_VIEW'
,p_readonly_for_each_row=>false
,p_help_text=>'When the target is an existing table/view, the data type of that column is shown otherwise it is determined from the file contents.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980460654611811)
,p_name=>'DATA_ROW'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_ROW'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'First Data Row'
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
 p_id=>wwv_flow_api.id(56980370758611810)
,p_name=>'TABLE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TABLE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_AUTO_COMPLETE'
,p_heading=>'Table Column (header)'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>60
,p_value_alignment=>'LEFT'
,p_attribute_01=>'CONTAINS_IGNORE'
,p_attribute_04=>'Y'
,p_attribute_10=>'Y'
,p_is_required=>false
,p_max_length=>16000
,p_lov_type=>'SQL_QUERY'
,p_lov_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  c.column_name',
'from    all_tab_columns c',
'where   c.owner = :P4_SCHEMA',
'and     c.table_name = rtrim(ltrim(:P4_TABLE_VIEW, ''"''), ''"'')',
'order by',
'        c.column_name'))
,p_lov_display_extra=>true
,p_lov_cascade_parent_items=>'P4_SCHEMA,P4_TABLE_VIEW'
,p_ajax_items_to_submit=>'P4_SCHEMA,P4_TABLE_VIEW'
,p_ajax_optimize_refresh=>true
,p_filter_is_required=>false
,p_use_as_row_header=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'If you define an existing table/view, you must use the column names of the existing table/view as file table column (autocompletion available).',
'',
''))
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(56980310674611809)
,p_name=>'FILE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'File Column'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>50
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
 p_id=>wwv_flow_api.id(56980184232611808)
,p_name=>'SEQ_ID'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'SEQ_ID'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>40
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>true
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(56979979952611806)
,p_internal_uid=>50914421037625826
,p_is_editable=>true
,p_edit_operations=>'u:d'
,p_lost_update_check_type=>'VALUES'
,p_submit_checked_rows=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_show_nulls_as=>'-'
,p_select_first_row=>true
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>false
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SAVE'
,p_enable_save_public_report=>false
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
 p_id=>wwv_flow_api.id(57257947539668201)
,p_interactive_grid_id=>wwv_flow_api.id(56979979952611806)
,p_static_id=>'297047'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_rows_per_page=>5
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(57257978520668202)
,p_report_id=>wwv_flow_api.id(57257947539668201)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(103512225658865857)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>10
,p_column_id=>wwv_flow_api.id(103921640146902991)
,p_is_visible=>false
,p_is_frozen=>false
,p_sort_order=>1
,p_sort_direction=>'ASC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57263030885668229)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>0
,p_column_id=>wwv_flow_api.id(56981006608611816)
,p_is_visible=>true
,p_is_frozen=>true
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57262505888668227)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>8
,p_column_id=>wwv_flow_api.id(56980883719611815)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57262011758668225)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(56980789708611814)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>50
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57261481446668224)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(56980668226611813)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57261035386668222)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(56980607634611812)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57260474280668221)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(56980460654611811)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57260057441668219)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(56980370758611810)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>145
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57259547112668217)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(56980310674611809)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>75
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(57258969387668215)
,p_view_id=>wwv_flow_api.id(57257978520668202)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(56980184232611808)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57218745171480380)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(57086684584461176)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57218657945480380)
,p_plug_name=>'Target'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(57096232842461183)
,p_plug_display_sequence=>30
,p_plug_new_grid_row=>false
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57329093782896693)
,p_plug_name=>'Target (Existing Table/View)'
,p_parent_plug_id=>wwv_flow_api.id(57218657945480380)
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(57096232842461183)
,p_plug_display_sequence=>50
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57328976927896692)
,p_plug_name=>'Target (New Table)'
,p_parent_plug_id=>wwv_flow_api.id(57218657945480380)
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(57096232842461183)
,p_plug_display_sequence=>40
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(57218494979480380)
,p_plug_name=>'Wizard Progress'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(57074706508461172)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_list_id=>wwv_flow_api.id(57206405154480329)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(57128954616461204)
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(63198551388444200)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(56979926771611805)
,p_button_name=>'REFRESH'
,p_button_static_id=>'refresh'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(57148551375461217)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Refresh Column Info'
,p_button_position=>'ABOVE_BOX'
,p_icon_css_classes=>'fa-refresh'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(58679839034811691)
,p_button_sequence=>50
,p_button_plug_id=>wwv_flow_api.id(57218745171480380)
,p_button_name=>'LOAD'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(57148551375461217)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Load'
,p_button_position=>'BELOW_BOX'
,p_button_comment=>'javascript:apex.confirm(''Are you sure you want to load this file?'',''LOAD'');'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(57222241723480382)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(57218745171480380)
,p_button_name=>'CANCEL'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(57148551375461217)
,p_button_image_alt=>'Cancel'
,p_button_position=>'REGION_TEMPLATE_CLOSE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(57222434879480382)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(57218745171480380)
,p_button_name=>'PREVIOUS'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(57148455949461216)
,p_button_image_alt=>'Previous'
,p_button_position=>'REGION_TEMPLATE_PREVIOUS'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-chevron-left'
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(57328835631896690)
,p_branch_name=>'Next Page'
,p_branch_action=>'f?p=&APP_ID.:5:&SESSION.::&DEBUG.:RP,5:P5_FILE_ID,P5_FILE_NAME,P5_CSV_FILE,P5_VIEW_NAME,P5_SHEET_NAMES,P5_LAST_EXCEL_COLUMN_NAME,P5_HEADER_ROW_FROM,P5_DATA_ROW_FROM,P5_DETERMINE_DATATYPE,P5_NEW_TABLE,P5_ACTION,P5_NR_ROWS,P5_OWNER,P5_TABLE,P5_SCHEMA,P5_TABLE_VIEW,P5_HEADER_ROW_TILL,P5_DATA_ROW_TILL:&P4_FILE_ID.,&P4_FILE_NAME.,&P4_CSV_FILE.,&P4_VIEW_NAME.,\&P4_SHEET_NAMES.\,&P4_LAST_EXCEL_COLUMN_NAME.,&P4_HEADER_ROW_FROM.,&P4_DATA_ROW_FROM.,&P4_DETERMINE_DATATYPE.,&P4_NEW_TABLE.,&P4_ACTION.,&P4_NR_ROWS.,&P4_OWNER.,&P4_TABLE.,&P4_SCHEMA.,&P4_TABLE_VIEW.,&P4_HEADER_ROW_TILL.,&P4_DATA_ROW_TILL.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_sequence=>10
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(57224218268480382)
,p_branch_name=>'Previous Page'
,p_branch_action=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.::P3_SHEET_NAMES:&P4_SHEET_NAMES.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'BEFORE_VALIDATION'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(57222434879480382)
,p_branch_sequence=>10
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(63199290163444208)
,p_branch_name=>'Refresh Column Info'
,p_branch_action=>'f?p=&APP_ID.:4:&SESSION.::&DEBUG.:RP,4:P4_FILE_ID,P4_FILE_NAME,P4_CSV_FILE,P4_VIEW_NAME,P4_SHEET_NAMES,P4_LAST_EXCEL_COLUMN_NAME,P4_HEADER_ROW_FROM,P4_DATA_ROW_FROM,P4_DETERMINE_DATATYPE,P4_NEW_TABLE,P4_ACTION,P4_NR_ROWS,P4_OWNER,P4_TABLE,P4_SCHEMA,P4_TABLE_VIEW,P4_HEADER_ROW_TILL,P4_TABLE_COLUMS_MATCH,P4_DATA_ROW_TILL:&P4_FILE_ID.,&P4_FILE_NAME.,&P4_CSV_FILE.,&P4_VIEW_NAME.,\&P4_SHEET_NAMES.\,&P4_LAST_EXCEL_COLUMN_NAME.,&P4_HEADER_ROW_FROM.,&P4_DATA_ROW_FROM.,&P4_DETERMINE_DATATYPE.,&P4_NEW_TABLE.,&P4_ACTION.,&P4_NR_ROWS.,&P4_OWNER.,&P4_TABLE.,&P4_SCHEMA.,&P4_TABLE_VIEW.,&P4_HEADER_ROW_TILL.,&P4_TABLE_COLUMS_MATCH.,&P4_DATA_ROW_TILL.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'BEFORE_VALIDATION'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(63198551388444200)
,p_branch_sequence=>20
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(63871739695579997)
,p_name=>'P4_DATA_ROW_TILL'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_prompt=>'Last Data Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_display_when=>'P4_CSV_FILE'
,p_display_when2=>'0'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The last data row to process where empty means all starting from the first data row.'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(63196847439444183)
,p_name=>'P4_HEADER_ROW_TILL'
,p_is_required=>true
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_item_default=>'1'
,p_prompt=>'Last Header Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'If the file contains a header this is the last row of the header. A value of 0 indicates no header. '
,p_attribute_01=>'0'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(63154394682295539)
,p_name=>'P4_OBJECT_NAME'
,p_item_sequence=>170
,p_item_plug_id=>wwv_flow_api.id(57218657945480380)
,p_use_cache_before_default=>'NO'
,p_prompt=>'Object Name'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(63025223409465106)
,p_name=>'P4_VIEW_NAME'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_prompt=>'View Name'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_begin_on_new_line=>'N'
,p_colspan=>4
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The name of the view containing the load file info.'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(63024866328461258)
,p_name=>'P4_CSV_FILE'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(59134775768509595)
,p_name=>'P4_TABLE_COLUMS_MATCH'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(57329093782896693)
,p_use_cache_before_default=>'NO'
,p_item_default=>'1'
,p_prompt=>'Table Columns Must Match?'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'If true, the source columns ("Table Column (header)") must all be in the column names of the target table/view.',
'If false, no such verification is made yet but only when loading. This is useful for choosing the "Table Column (header)" from an auto completion list.'))
,p_attribute_01=>'CUSTOM'
,p_attribute_02=>'1'
,p_attribute_03=>'Yes'
,p_attribute_04=>'0'
,p_attribute_05=>'No'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(59133976007509587)
,p_name=>'P4_DETERMINE_DATATYPE'
,p_is_required=>true
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_item_default=>'2'
,p_prompt=>'Determine Data Type'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DETERMINE_DATATYPE'
,p_lov=>'.'||wwv_flow_api.id(103927733614962612)||'.'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_colspan=>3
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'Used when creating a table.'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57330509105896707)
,p_name=>'P4_OWNER'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(57328976927896692)
,p_item_default=>'&APPLICATION_OWNER.'
,p_prompt=>'New table schema to load into'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57329173448896694)
,p_name=>'P4_TABLE'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(57328976927896692)
,p_use_cache_before_default=>'NO'
,p_item_default=>'nvl(case when instr(:P4_SHEET_NAMES, '':'') = 0 then :P4_SHEET_NAMES end, :P4_FILE_NAME)'
,p_item_default_type=>'EXPRESSION'
,p_item_default_language=>'PLSQL'
,p_prompt=>'New table to load into'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The new table name (case sensitive).'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57328948640896691)
,p_name=>'P4_NEW_TABLE'
,p_is_required=>true
,p_item_sequence=>130
,p_item_plug_id=>wwv_flow_api.id(57218657945480380)
,p_use_cache_before_default=>'NO'
,p_item_default=>'0'
,p_prompt=>'New table?'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'Are we going to load into a new table or use an existing table/view?'
,p_attribute_01=>'CUSTOM'
,p_attribute_02=>'1'
,p_attribute_03=>'Yes'
,p_attribute_04=>'0'
,p_attribute_05=>'No'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57328024874896682)
,p_name=>'P4_ACTION'
,p_is_required=>true
,p_item_sequence=>140
,p_item_plug_id=>wwv_flow_api.id(57218657945480380)
,p_use_cache_before_default=>'NO'
,p_item_default=>'R'
,p_prompt=>'Action'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DML_ACTIONS'
,p_lov=>'.'||wwv_flow_api.id(59217749697825803)||'.'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#:t-Form-fieldContainer--radioButtonGroup'
,p_lov_display_extra=>'NO'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'The database manipulation action:',
'<ul>',
'    <li>Insert</li>',
'    <li>Replace which means emptying the table first and then insert</li>',
'    <li>Update which requires a key (at least one "Key?" true)</li>',
'    <li>Merge which means update if the record exists and otherwise an insert</li>',
'    <li>Delete which requires a key</li>',
'</ul>'))
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57327894666896681)
,p_name=>'P4_SCHEMA'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(57329093782896693)
,p_use_cache_before_default=>'NO'
,p_prompt=>'Table/View schema to load into'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_APPLICATION_OWNERS'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  distinct',
'        a.owner as d',
',       a.owner as r',
'from    apex_applications a',
'where   a.workspace_id = to_number(SYS_CONTEXT(''APEX$SESSION'',''WORKSPACE_ID''))',
'order by',
'        case when a.owner = ''&APPLICATION_OWNER.'' then 0 else 1 end',
',       d'))
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'The allowed schemas (the Oracle Apex parsing schemas of the workspace).'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57319944185627945)
,p_name=>'P4_NR_ROWS'
,p_item_sequence=>160
,p_item_plug_id=>wwv_flow_api.id(57218657945480380)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57319632140625892)
,p_name=>'P4_TABLE_VIEW'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(57329093782896693)
,p_use_cache_before_default=>'NO'
,p_prompt=>'Table/View to load into'
,p_display_as=>'NATIVE_POPUP_LOV'
,p_lov=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  distinct',
'        ''"'' || o.object_name || ''" '' || ''('' || o.object_type || '')'' as d',
',       ''"'' || o.object_name || ''"'' as r',
'from    all_objects o',
'where   o.owner = :P4_SCHEMA',
'and     o.object_type in (''TABLE'', ''VIEW'')',
'and     o.object_name not like ''%schema_version%'' -- Do not list the Flyway table',
'-- all table columns (headers) of the File must match the table/view',
'and     ( :P4_TABLE_COLUMS_MATCH = 0 or',
'          not',
'          ( exists',
'            ( select  t.header_row as table_column',
'              from    table(ext_load_file_pkg.display(:P4_FILE_ID)) t',
'              minus',
'              select  c.column_name',
'              from    all_tab_columns c',
'              where   c.owner = o.owner',
'              and     c.table_name = o.object_name',
'            )',
'          ) ',
'        )',
'order by',
'        d'))
,p_lov_cascade_parent_items=>'P4_SCHEMA,P4_TABLE_COLUMS_MATCH'
,p_ajax_items_to_submit=>'P4_SCHEMA,P4_TABLE_COLUMS_MATCH'
,p_ajax_optimize_refresh=>'Y'
,p_cSize=>60
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'An existing table or view.'
,p_attribute_01=>'DIALOG'
,p_attribute_02=>'FIRST_ROWSET'
,p_attribute_04=>'N'
);
wwv_flow_api.component_end;
end;
/
begin
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>151930114232313867
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57247783338569220)
,p_name=>'P4_FILE_NAME'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_prompt=>'File'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>4
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57246730446563254)
,p_name=>'P4_LAST_EXCEL_COLUMN_NAME'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_prompt=>'Last Column (A,B,...)'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_colspan=>2
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The last column you want to load into the database.'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57246435816560134)
,p_name=>'P4_SHEET_NAMES'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
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
,p_begin_on_new_line=>'N'
,p_display_when=>'P4_CSV_FILE'
,p_display_when2=>'1'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_read_only_when_type=>'ALWAYS'
,p_field_template=>wwv_flow_api.id(57147997654461215)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'The sheet to upload from the spreadsheet file.'
,p_attribute_01=>'MULTI'
,p_attribute_06=>'Y'
,p_attribute_08=>'CIC'
,p_attribute_10=>'800'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57246132360557731)
,p_name=>'P4_FILE_ID'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57220714155480381)
,p_name=>'P4_DATA_ROW_FROM'
,p_is_required=>true
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_item_default=>'0'
,p_prompt=>'First Data Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The first data row to process.'
,p_attribute_01=>'1'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57220273614480381)
,p_name=>'P4_HEADER_ROW_FROM'
,p_is_required=>true
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(57329818588896700)
,p_use_cache_before_default=>'NO'
,p_item_default=>'1'
,p_prompt=>'First Header Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_field_template=>wwv_flow_api.id(57147718564461213)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'If the file contains a header this is the first row of the header. A value of 0 indicates no header. If there is a header the table field "Table Column (header)" will contain that information, otherwise the table field will be the same as the "File C'
||'olumn".'
,p_attribute_01=>'0'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(57330602088896708)
,p_validation_name=>'P4_TABLE not null'
,p_validation_sequence=>10
,p_validation=>'P4_TABLE'
,p_validation_type=>'ITEM_NOT_NULL'
,p_error_message=>'#LABEL# must have some value.'
,p_validation_condition=>'P4_NEW_TABLE'
,p_validation_condition2=>'0'
,p_validation_condition_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_associated_item=>wwv_flow_api.id(57329173448896694)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(57330695248896709)
,p_validation_name=>'P4_SCHEMA not null'
,p_validation_sequence=>20
,p_validation=>'P4_SCHEMA'
,p_validation_type=>'ITEM_NOT_NULL'
,p_error_message=>'#LABEL# must have some value.'
,p_validation_condition=>'P4_NEW_TABLE'
,p_validation_condition2=>'0'
,p_validation_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_associated_item=>wwv_flow_api.id(57327894666896681)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(57330810675896710)
,p_validation_name=>'P4_TABLE_VIEW not null'
,p_validation_sequence=>30
,p_validation=>'P4_TABLE_VIEW'
,p_validation_type=>'ITEM_NOT_NULL'
,p_error_message=>'#LABEL# must have some value.'
,p_validation_condition=>'P4_NEW_TABLE'
,p_validation_condition2=>'0'
,p_validation_condition_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_associated_item=>wwv_flow_api.id(57319632140625892)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(62984210684037930)
,p_tabular_form_region_id=>wwv_flow_api.id(56979926771611805)
,p_validation_name=>'Validate Column Info'
,p_validation_sequence=>40
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'begin',
'  ext_load_file_pkg.validate',
'  ( p_excel_column_name => :FILE_COLUMN',
'  , p_header_row => :TABLE_COLUMN',
'  , p_data_type => :DATA_TYPE',
'  , p_format_mask => :FORMAT_MASK',
'  , p_in_key => :IN_KEY',
'  , p_default_value => :DEFAULT_VALUE',
'  );',
'  return null; -- Okay',
'exception  ',
'  when others',
'  then',
'    return sqlerrm;',
'end;'))
,p_validation2=>'PLSQL'
,p_validation_type=>'FUNC_BODY_RETURNING_ERR_TEXT'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(63200151884444216)
,p_validation_name=>'CheckHeaderRowTill'
,p_validation_sequence=>50
,p_validation=>wwv_flow_string.join(wwv_flow_t_varchar2(
'(:P4_HEADER_ROW_FROM = 0 AND :P4_HEADER_ROW_TILL = 0) OR',
'(:P4_HEADER_ROW_FROM > 0 AND :P4_HEADER_ROW_FROM <= :P4_HEADER_ROW_TILL)'))
,p_validation2=>'PLSQL'
,p_validation_type=>'EXPRESSION'
,p_error_message=>'First and last header rows must be both 0 (meaning no header) or the last header row must be at least the first header row.'
,p_associated_item=>wwv_flow_api.id(63196847439444183)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(63200951751444224)
,p_validation_name=>'CheckHeaderRowFrom'
,p_validation_sequence=>60
,p_validation=>':P4_HEADER_ROW_FROM >= 0'
,p_validation2=>'PLSQL'
,p_validation_type=>'EXPRESSION'
,p_error_message=>'First header row must be 0 (meaning no header) or at least 1.'
,p_associated_item=>wwv_flow_api.id(57220273614480381)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_validation(
 p_id=>wwv_flow_api.id(63200211714444217)
,p_validation_name=>'CheckDataRowFrom'
,p_validation_sequence=>70
,p_validation=>':P4_DATA_ROW_FROM >= 1 AND :P4_DATA_ROW_FROM > :P4_HEADER_ROW_TILL'
,p_validation2=>'PLSQL'
,p_validation_type=>'EXPRESSION'
,p_error_message=>'The first data row must be greater than the last header row.'
,p_associated_item=>wwv_flow_api.id(57220714155480381)
,p_error_display_location=>'INLINE_WITH_FIELD_AND_NOTIFICATION'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(57222635872480382)
,p_name=>'Cancel Dialog'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(57222241723480382)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(57223370831480382)
,p_event_id=>wwv_flow_api.id(57222635872480382)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_DIALOG_CANCEL'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(56979689320611803)
,p_name=>'Enable Refresh Button'
,p_event_sequence=>20
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P4_HEADER_ROW_FROM,P4_DATA_ROW_FROM,P4_DETERMINE_DATATYPE,P4_HEADER_ROW_TILL,P4_DATA_ROW_TILL'
,p_bind_type=>'bind'
,p_bind_event_type=>'change'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(63199364861444209)
,p_event_id=>wwv_flow_api.id(56979689320611803)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'BUTTON'
,p_affected_button_id=>wwv_flow_api.id(63198551388444200)
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(59135265414509600)
,p_name=>'Refresh Column Info from Target'
,p_event_sequence=>40
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P4_TABLE_VIEW'
,p_condition_element=>'P4_TABLE_VIEW'
,p_triggering_condition_type=>'NOT_NULL'
,p_bind_type=>'bind'
,p_bind_event_type=>'change'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(59135716157509604)
,p_event_id=>wwv_flow_api.id(59135265414509600)
,p_event_result=>'TRUE'
,p_action_sequence=>40
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_REFRESH'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_api.id(56979926771611805)
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(57329280537896695)
,p_name=>'Hide / Show Table Regions'
,p_event_sequence=>50
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P4_NEW_TABLE'
,p_condition_element=>'P4_NEW_TABLE'
,p_triggering_condition_type=>'EQUALS'
,p_triggering_expression=>'0'
,p_bind_type=>'bind'
,p_bind_event_type=>'change'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(57329597262896698)
,p_event_id=>wwv_flow_api.id(57329280537896695)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_api.id(57328976927896692)
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(57329400179896696)
,p_event_id=>wwv_flow_api.id(57329280537896695)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_api.id(57329093782896693)
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(57329728792896699)
,p_event_id=>wwv_flow_api.id(57329280537896695)
,p_event_result=>'FALSE'
,p_action_sequence=>20
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_HIDE'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_api.id(57329093782896693)
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(57329464258896697)
,p_event_id=>wwv_flow_api.id(57329280537896695)
,p_event_result=>'TRUE'
,p_action_sequence=>30
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_HIDE'
,p_affected_elements_type=>'REGION'
,p_affected_region_id=>wwv_flow_api.id(57328976927896692)
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(56981231527611818)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_region_id=>wwv_flow_api.id(56979926771611805)
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Column Info - Save Interactive Grid Data'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'ext_load_file_pkg.dml',
'( p_action => :APEX$ROW_STATUS',
', p_apex_file_id => :P4_FILE_ID',
', p_seq_id => :SEQ_ID',
', p_excel_column_name => :FILE_COLUMN',
', p_header_row => :TABLE_COLUMN',
', p_data_row => :DATA_ROW',
', p_data_type => :DATA_TYPE',
', p_format_mask => :FORMAT_MASK',
', p_in_key => case :IN_KEY when ''N'' then 0 else 1 end',
', p_default_value => :DEFAULT_VALUE',
');'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(57328465856896687)
,p_process_sequence=>40
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load File'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'  l_object_name constant varchar2(1000) := ',
'    case ',
'      when :P4_NEW_TABLE = 1 and :P4_OWNER is not null and :P4_TABLE is not null',
'      then DBMS_ASSERT.ENQUOTE_NAME(:P4_OWNER, false) || ''.'' || DBMS_ASSERT.ENQUOTE_NAME(:P4_TABLE, false)',
'      when :P4_NEW_TABLE = 0 and :P4_SCHEMA is not null and :P4_TABLE_VIEW is not null',
'      then DBMS_ASSERT.ENQUOTE_NAME(:P4_SCHEMA, false) || ''.'' || :P4_TABLE_VIEW',
'    end;',
'  l_cursor integer := null; ',
'  ',
'  procedure ddl(p_sql_text in dbms_sql.varchar2a)',
'  is',
'  begin',
'    dbug.print(dbug."debug", ''p_sql_text.count: %s'', p_sql_text.count);',
'    ',
'    if p_sql_text.count = 0',
'    then',
'      return;',
'    end if;',
'      ',
'    dbms_sql.parse',
'    ( c => l_cursor',
'    , statement => p_sql_text',
'    , lb => p_sql_text.first',
'    , ub => p_sql_text.last',
'    , lfflg => true',
'    , language_flag => dbms_sql.native',
'    );',
'  end ddl;',
'  ',
'  procedure ddl(p_statement in varchar2)',
'  is',
'  begin',
'    dbug.print(dbug."debug", ''p_statement: %s'', p_statement);',
'    ',
'    dbms_sql.parse',
'    ( c => l_cursor',
'     , statement => p_statement',
'     , language_flag => dbms_sql.native',
'    );',
'  end ddl;',
'  ',
'  procedure cleanup',
'  is',
'  begin',
'    if l_cursor is not null',
'    then',
'      dbms_sql.close_cursor(l_cursor);',
'    end if;',
'  end cleanup;',
'begin',
'  if :P4_NEW_TABLE = 1',
'  then',
'    -- no validations before creating a table',
'    l_cursor := dbms_sql.open_cursor;',
'',
'    ddl',
'    ( ext_load_file_pkg.create_table_statement',
'      ( p_apex_file_id => :P4_FILE_ID',
'      , p_table_name => l_object_name',
'      )',
'    );',
'    ',
'    if DBMS_ASSERT.ENQUOTE_NAME(:P4_OWNER, false)',
'       != DBMS_ASSERT.ENQUOTE_NAME(ext_load_file_pkg.get_load_data_owner, false)',
'    then',
'      ddl',
'      ( ''grant select,insert,update,delete on '' ||',
'        l_object_name ||',
'        '' to '' ||',
'        DBMS_ASSERT.ENQUOTE_NAME(ext_load_file_pkg.get_load_data_owner, false)',
'      );        ',
'    end if;',
'  end if;',
'  ',
'  -- validate is called in here anyhow',
'  :P4_NR_ROWS := ',
'    ext_load_file_pkg.load',
'    ( p_apex_file_id => :P4_FILE_ID',
'    , p_sheet_names => :P4_SHEET_NAMES',
'    , p_last_excel_column_name => :P4_LAST_EXCEL_COLUMN_NAME ',
'    , p_header_row_from => :P4_HEADER_ROW_FROM',
'    , p_header_row_till => :P4_HEADER_ROW_TILL',
'    , p_data_row_from => :P4_DATA_ROW_FROM',
'    , p_data_row_till => :P4_DATA_ROW_TILL',
'    , p_determine_datatype => :P4_DETERMINE_DATATYPE ',
'    , p_object_name => l_object_name',
'    , p_action => :P4_ACTION',
'    );',
'    ',
'  cleanup;',
'exception',
'  when others',
'  then',
'    cleanup;',
'    raise;',
'end;'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_api.id(58679839034811691)
,p_process_success_message=>'Number of rows processed: &P4_NR_ROWS.'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(56981444076611820)
,p_process_sequence=>20
,p_process_point=>'BEFORE_BOX_BODY'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Initialise'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'ext_load_file_pkg.init',
'( p_apex_file_id => :P4_FILE_ID',
', p_sheet_names => :P4_SHEET_NAMES',
', p_last_excel_column_name => :P4_LAST_EXCEL_COLUMN_NAME',
', p_header_row_from => :P4_HEADER_ROW_FROM',
', p_header_row_till => :P4_HEADER_ROW_TILL',
', p_data_row_from => :P4_DATA_ROW_FROM',
', p_data_row_till => :P4_DATA_ROW_TILL',
', p_determine_datatype => :P4_DETERMINE_DATATYPE',
', p_view_name => :P4_VIEW_NAME',
');',
'ext_load_file_pkg.parse_object_name',
'( p_fq_object_name => :P4_OBJECT_NAME',
', p_owner => :P4_SCHEMA',
', p_object_name => :P4_TABLE_VIEW',
');',
'if :P4_TABLE_VIEW is not null',
'then',
'  :P4_TABLE_VIEW := ''"'' || :P4_TABLE_VIEW || ''"'';',
'end if;  ',
''))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.component_end;
end;
/
