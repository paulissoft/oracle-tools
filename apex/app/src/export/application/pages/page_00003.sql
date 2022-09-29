prompt --application/pages/page_00003
begin
--   Manifest
--     PAGE: 00003
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
 p_id=>3
,p_user_interface_id=>wwv_flow_api.id(18420547356600209)
,p_name=>'Preview File'
,p_page_mode=>'MODAL'
,p_step_title=>'Preview File'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var logger = oracleTools.initLogger()',
'var field_names =    ["VIEW_NAME", "OBJECT_NAME", "SHEET_NAMES", "LAST_EXCEL_COLUMN_NAME", "HEADER_ROW_FROM", "HEADER_ROW_TILL", "DATA_ROW_FROM", "DATA_ROW_TILL", "DETERMINE_DATATYPE"];',
'var default_values = [""         , ""           , ""           , "ZZ"                    , "1"              , "1"              , "2"            , ""             , "2"                 ];',
'    ',
'function SelectLoadFileInfo (data) {',
'  let selectedRecord = null',
'  let model = null',
'  ',
'  logger.debug(''>SelectLoadFileInfo'')',
'',
'  logger.debug(''data: '', data)',
'',
'  let count = apex.item("P3_LOAD_FILE_INFO_HISTORY_COUNT").getValue()',
'  ',
'  logger.debug(''P3_LOAD_FILE_INFO_HISTORY_COUNT: '', count)',
'  ',
'  apex.item("P3_LOAD_FILE_INFO_HISTORY_COUNT").setValue(count + 1)',
'  ',
'  if (count == 0) {  ',
'    if (data != null && data.selectedRecords != null && data.selectedRecords.length == 1 && data.selectedRecords[0] != null) {',
'      selectedRecord = data.selectedRecords[0]',
'      model = data.model',
'    }',
'',
'    logger.debug(''selectedRecord: '', selectedRecord)',
'',
'    for (let i = 0; i < field_names.length; i++) {',
'      let value = (model !== null && selectedRecord !== null ? model.getValue(selectedRecord, field_names[i]) : default_values[i])',
'',
'      logger.debug(''field: '', field_names[i], ''; value: '', value)',
'',
'      // enable the field',
'      apex.item(''P3_'' + field_names[i]).enable()',
'',
'      // must we change the item?',
'      if (apex.item(''P3_'' + field_names[i]).getValue() === null ||',
'          apex.item(''P3_'' + field_names[i]).getValue() != value) {',
'        // change the field',
'        if (field_names[i] === ''SHEET_NAMES'') {',
'          // set value using jQuery  ',
'          $("#" + ''P3_'' + field_names[i]).val(value.split('':'')).trigger("change")',
'        } else {',
'          apex.item(''P3_'' + field_names[i]).setValue(value)',
'        }',
'      }',
'',
'      // disable the field?  ',
'      if ((field_names[i] === ''SHEET_NAMES'' && apex.item(''P3_CSV_FILE'').getValue() == 0) || field_names[i] === ''LAST_EXCEL_COLUMN_NAME'') {',
'        ; // keep enabled',
'      } else {',
'        apex.item(''P3_'' + field_names[i]).disable()',
'      }',
'    } ',
'  }',
'  ',
'  apex.item("P3_LOAD_FILE_INFO_HISTORY_COUNT").setValue(count)',
'  ',
'  logger.debug(''<SelectLoadFileInfo'')',
'}',
'',
'function EnableItems () {',
'  logger.debug(''>EnableItems'')',
'  for (let i = 0; i < field_names.length; i++) {',
'    apex.item("P3_" + field_names[i]).enable()',
'  }',
'  logger.debug(''<EnableItems'')',
'}',
'',
'function EnableDisableAllSheets(value) {',
'  //apex.message.alert(''EnableDisableAllSheets'', function(){})',
'  let option = $(''#P3_SHEET_NAMES'').select2(''destroy'').find(''option'')',
'  ',
'  if (option !== null) {',
'      let prop = option.prop(''selected'', value)',
'      ',
'      if (prop !== null) {',
'          prop.end().select2()',
'      }',
'  } ',
'    ',
'  document.querySelector("#P3_SHEET_NAMES_CONTAINER > div.t-Form-inputContainer.col.col-8 > div > span").style.width = "400px"',
'    ',
'  apex.region("load_file_info_history").refresh()',
'}',
'',
'function EnableAllSheets () {',
'  logger.debug(''>EnableAllSheets'')',
'  // $(''#P3_SHEET_NAMES'').select2(''destroy'').find(''option'').prop(''selected'', ''selected'').end().select2()',
'  EnableDisableAllSheets(''selected'') ',
'  logger.debug(''<EnableAllSheets'')',
'}    ',
'',
'function DisableAllSheets () {',
'  logger.debug(''>DisableAllSheets'')',
'  // $(''#P3_SHEET_NAMES'').select2(''destroy'').find(''option'').prop(''selected'', false).end().select2()',
'  EnableDisableAllSheets(false)',
'  logger.debug(''<DisableAllSheets'')',
'}',
'',
'function ChangeSheetNames () {',
'  logger.debug(''>ChangeSheetNames'')',
'  //apex.message.alert(''ChangeSheetNames'', function(){})',
'  apex.region("load_file_info_history").refresh()',
'  logger.debug(''<ChangeSheetNames'')',
'}',
'',
'function CloseSheetNames () {',
'  logger.debug(''>CloseSheetNames'')',
'  //apex.message.alert(''CloseSheetNames'', function(){})',
'  apex.region("load_file_info_history").refresh()',
'  logger.debug(''<CloseSheetNames'')',
'}'))
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'parent.$(''.ui-dialog-titlebar-close'').hide() // hide the upper right close dialog button so we can only use the CANCEL button',
'',
'logger.enableAll();'))
,p_inline_css=>wwv_flow_string.join(wwv_flow_t_varchar2(
'/* Have the buttons float right */',
'.toggle-all-sheets {',
'    float: right;',
'    margin-left: 350px;',
'}',
'',
'#P3_SHEET_NAMES_CONTAINER > div.t-Form-inputContainer.col.col-8 > div > span {',
'    width: 400px;    ',
'}'))
,p_step_template=>wwv_flow_api.id(18305929945600118)
,p_page_template_options=>'#DEFAULT#:ui-dialog--stretch'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>',
'This is the second step of the wizard to upload a spreadsheet file into the database.    ',
'</p>',
'',
'<p>',
'A Download/View button is provided so you can determine the sheet(s) and/or last column to load into the database.  ',
'</p>',
'',
'<p>',
'Furthermore a load file info history report is shown with information stored when you actually load a file in the next step of the wizard. You can remove history from this grid if needed by selecting line(s), choosing Delete Row(s) from the Row/Selec'
||'tion Action menu next to the selectors and then press the Save button.',
'</p>',
'',
'<p>',
'The load file info history allows you to (de)select a line in order to (un)set information like object name, sheet name, last excel column, first header row, last header row, first data row or determine data type. This report is sorted by similarity '
||'between file names (best matches first) and within that by descending date.',
'</p>',
'',
'<p>',
'For every load file info there is also a detail report showing the columns with properties like file column, table column, data type, part of the key and format mask for date/timestamp fields. Selecting a load file info line also selects those column'
||'s with their properties to be used in the next wizard step.    ',
'</p>',
''))
,p_last_updated_by=>'GERT.JAN.PAULISSEN@GMAIL.COM'
,p_last_upd_yyyymmddhh24miss=>'20210607032406'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(50539956092307893)
,p_plug_name=>'Load file info history'
,p_region_name=>'load_file_info_history'
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--hiddenOverflow:t-Form--slimPadding'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(18346340098600141)
,p_plug_display_sequence=>30
,p_plug_grid_column_span=>8
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select vw.view_name,',
'       obj.created,',
'       vw.file_name,',
'       vw.mime_type,',
'       vw.object_name,',
'       vw.sheet_names,',
'       vw.last_excel_column_name,',
'       vw.header_row_from,',
'       vw.header_row_till,',
'       vw.header_row_from||''-''||vw.header_row_till as header_rows,',
'       vw.data_row_from,',
'       vw.data_row_till,',
'       vw.data_row_from||''-''||vw.data_row_till as data_rows,',
'       vw.determine_datatype,',
'       vw.determine_datatype as determine_datatype_display,',
'       utl_match.edit_distance_similarity',
'       ( vw.file_name || ''|'' || case when :P3_SHEET_NAMES is not null then vw.sheet_names end -- GJP 2020-07-01 when page item is empty ignore view sheet names',
'       , :P3_FILE_NAME || ''|'' || :P3_SHEET_NAMES',
'       ) as file_sheet_score_perc',
'  from ext_load_file_object_v vw',
'       inner join all_objects obj',
'       on obj.object_name = vw.view_name and obj.object_type = ''VIEW''',
' where ( :P3_CSV_FILE = 1 and vw.mime_type = ''text/csv'' )',
'    or ( :P3_CSV_FILE != 1 and vw.mime_type != ''text/csv'' )',
''))
,p_plug_source_type=>'NATIVE_IG'
,p_ajax_items_to_submit=>'P3_CSV_FILE,P3_FILE_NAME,P3_SHEET_NAMES'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50537663534307871)
,p_name=>'VIEW_NAME'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'VIEW_NAME'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>30
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>true
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50537086873307869)
,p_name=>'FILE_NAME'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_NAME'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'File Name'
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
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The name of the file uploaded.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50536409835307868)
,p_name=>'MIME_TYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'MIME_TYPE'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Mime Type'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>80
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
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The media type identifier for file formats and format contents.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50535869058307868)
,p_name=>'OBJECT_NAME'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'OBJECT_NAME'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Object Name'
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
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The object loaded into.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50535247523307868)
,p_name=>'SHEET_NAMES'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'SHEET_NAMES'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Sheet(s)'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>100
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
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The sheet to upload from the spreadsheet file.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50534660657307867)
,p_name=>'LAST_EXCEL_COLUMN_NAME'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'LAST_EXCEL_COLUMN_NAME'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Last Column<br/>(A,B,...)'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>110
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The last column you want to load into the database.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50531665971307866)
,p_name=>'DATA_ROW_FROM'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_ROW_FROM'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>180
,p_attribute_01=>'Y'
,p_filter_is_required=>false
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(50531114894307866)
,p_name=>'DETERMINE_DATATYPE_DISPLAY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DETERMINE_DATATYPE_DISPLAY'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_SELECT_LIST'
,p_heading=>'Determine<br/>Data Type'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>140
,p_value_alignment=>'CENTER'
,p_is_required=>true
,p_lov_type=>'SHARED'
,p_lov_id=>wwv_flow_api.id(65177840871101570)
,p_lov_display_extra=>false
,p_lov_display_null=>false
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'LOV'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_enable_pivot=>false
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_help_text=>'Used when creating a table.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25121604301718953)
,p_name=>'DATA_ROWS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_ROWS'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Data<br/>Rows'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>130
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>81
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(25121508307718952)
,p_name=>'DATA_ROW_TILL'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DATA_ROW_TILL'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>190
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24449974659583172)
,p_name=>'HEADER_ROW_TILL'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'HEADER_ROW_TILL'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>170
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24449915012583171)
,p_name=>'HEADER_ROW_FROM'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'HEADER_ROW_FROM'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>160
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24447803947583150)
,p_name=>'HEADER_ROWS'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'HEADER_ROWS'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_TEXT_FIELD'
,p_heading=>'Header<br/>Rows'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>120
,p_value_alignment=>'LEFT'
,p_attribute_05=>'BOTH'
,p_is_required=>false
,p_max_length=>81
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24233437401176879)
,p_name=>'FILE_SHEET_SCORE_PERC'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_SHEET_SCORE_PERC'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_PCT_GRAPH'
,p_heading=>'File + Sheet<br/>Score (%)'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>70
,p_value_alignment=>'CENTER'
,p_attribute_01=>'Y'
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
 p_id=>wwv_flow_api.id(24233048030176875)
,p_name=>'DETERMINE_DATATYPE'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'DETERMINE_DATATYPE'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>150
,p_attribute_01=>'Y'
,p_filter_is_required=>false
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24232754441176872)
,p_name=>'APEX$ROW_SELECTOR'
,p_item_type=>'NATIVE_ROW_SELECTOR'
,p_display_sequence=>10
,p_attribute_01=>'Y'
,p_attribute_02=>'Y'
,p_attribute_03=>'N'
,p_enable_hide=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24232634623176871)
,p_name=>'APEX$ROW_ACTION'
,p_item_type=>'NATIVE_ROW_ACTION'
,p_display_sequence=>20
,p_enable_hide=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24230613380176851)
,p_name=>'CREATED'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'CREATED'
,p_data_type=>'DATE'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Time Created'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>50
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_format_mask=>'DD-MON-YYYY HH24:MI:SS'
,p_enable_filter=>true
,p_filter_is_required=>false
,p_filter_date_ranges=>'ALL'
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>true
,p_enable_control_break=>true
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>true
,p_escape_on_http_output=>true
,p_help_text=>'The creation date of the view containing the file load info.'
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(50539442130307885)
,p_internal_uid=>113781800853010865
,p_is_editable=>true
,p_edit_operations=>'d'
,p_lost_update_check_type=>'VALUES'
,p_submit_checked_rows=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_max_row_count=>100000
,p_show_nulls_as=>'-'
,p_select_first_row=>true
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>false
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET:SAVE'
,p_enable_save_public_report=>true
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>true
,p_enable_mail_download=>true
,p_fixed_header=>'REGION'
,p_fixed_header_max_height=>300
,p_show_icon_view=>false
,p_show_detail_view=>false
,p_javascript_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'function(config) {',
'    config.initialSelection = false;',
'    return config',
'} '))
);
wwv_flow_api.create_ig_report(
 p_id=>wwv_flow_api.id(50539010225307882)
,p_interactive_grid_id=>wwv_flow_api.id(50539442130307885)
,p_static_id=>'297035'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_rows_per_page=>5
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(50538911449307881)
,p_report_id=>wwv_flow_api.id(50539010225307882)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50537207190307870)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(50537663534307871)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50536668939307868)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(50537086873307869)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>200
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50536011300307868)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(50536409835307868)
,p_is_visible=>false
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50535492936307868)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>8
,p_column_id=>wwv_flow_api.id(50535869058307868)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>170
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50534898831307867)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(50535247523307868)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>100
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50534277470307867)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(50534660657307867)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>90
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50531334478307866)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>10
,p_column_id=>wwv_flow_api.id(50531665971307866)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>110
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(50530759386307866)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>16
,p_column_id=>wwv_flow_api.id(50531114894307866)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>180
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25628404072057007)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>11
,p_column_id=>wwv_flow_api.id(25121604301718953)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>50
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(25627931519057003)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>15
,p_column_id=>wwv_flow_api.id(25121508307718952)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24560936970751461)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>14
,p_column_id=>wwv_flow_api.id(24449974659583172)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24560291834751455)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>13
,p_column_id=>wwv_flow_api.id(24449915012583171)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24524780811630077)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>9
,p_column_id=>wwv_flow_api.id(24447803947583150)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>60
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24387854957022966)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(24233437401176879)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>125
,p_sort_order=>1
,p_sort_direction=>'DESC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24358201409672715)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>12
,p_column_id=>wwv_flow_api.id(24233048030176875)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24332329930167693)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>0
,p_column_id=>wwv_flow_api.id(24232634623176871)
,p_is_visible=>true
,p_is_frozen=>true
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24240375651238182)
,p_view_id=>wwv_flow_api.id(50538911449307881)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(24230613380176851)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>130
,p_sort_order=>2
,p_sort_direction=>'DESC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(24229401383176839)
,p_plug_name=>'Load file details'
,p_region_template_options=>'#DEFAULT#:t-Region--noPadding:t-Region--hiddenOverflow'
,p_component_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(18346340098600141)
,p_plug_display_sequence=>40
,p_include_in_reg_disp_sel_yn=>'Y'
,p_plug_new_grid_row=>false
,p_plug_display_point=>'BODY'
,p_query_type=>'SQL'
,p_plug_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select VIEW_NAME,',
'       EXCEL_COLUMN_NAME AS FILE_COLUMN,',
'       HEADER_ROW AS TABLE_COLUMN,',
'       DATA_TYPE,',
'       FORMAT_MASK,',
'       IN_KEY,',
'       DEFAULT_VALUE,',
'       ext_load_file_pkg.excel_column_name2number(EXCEL_COLUMN_NAME) as FILE_COLUMN_ORDER',
'  from EXT_LOAD_FILE_COLUMN_V'))
,p_plug_source_type=>'NATIVE_IG'
,p_master_region_id=>wwv_flow_api.id(50539956092307893)
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(65171797779041950)
,p_name=>'FILE_COLUMN_ORDER'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_COLUMN_ORDER'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_NUMBER_FIELD'
,p_heading=>'File Column Order'
,p_heading_alignment=>'RIGHT'
,p_display_sequence=>100
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
 p_id=>wwv_flow_api.id(24230234074176847)
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
 p_id=>wwv_flow_api.id(24230160014176846)
,p_name=>'IN_KEY'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'IN_KEY'
,p_data_type=>'NUMBER'
,p_is_query_only=>false
,p_item_type=>'NATIVE_SELECT_LIST'
,p_heading=>'Key?'
,p_heading_alignment=>'CENTER'
,p_display_sequence=>80
,p_value_alignment=>'CENTER'
,p_is_required=>false
,p_lov_type=>'SHARED'
,p_lov_id=>wwv_flow_api.id(24354252557614073)
,p_lov_display_extra=>false
,p_lov_display_null=>false
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
 p_id=>wwv_flow_api.id(24230053385176845)
,p_name=>'FORMAT_MASK'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FORMAT_MASK'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Format mask'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>70
,p_value_alignment=>'LEFT'
,p_attribute_02=>'VALUE'
,p_enable_filter=>true
,p_filter_operators=>'C:S:CASE_INSENSITIVE:REGEXP'
,p_filter_is_required=>false
,p_filter_text_case=>'MIXED'
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24229872623176844)
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
,p_filter_exact_match=>true
,p_filter_lov_type=>'DISTINCT'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
,p_escape_on_http_output=>true
,p_help_text=>'When the target is an existing table/view, the data type of that column is shown otherwise it is determined from the file contents.'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24229787223176843)
,p_name=>'TABLE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'TABLE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'Table Column (header)'
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
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>false
,p_duplicate_value=>true
,p_include_in_export=>false
,p_escape_on_http_output=>true
,p_help_text=>'If you define an existing table/view, you must use the column names of the existing table/view as file table column (autocompletion available).'
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
,p_default_id_offset=>67978470344966559
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24229679592176842)
,p_name=>'FILE_COLUMN'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'FILE_COLUMN'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_DISPLAY_ONLY'
,p_heading=>'File Column'
,p_heading_alignment=>'LEFT'
,p_display_sequence=>40
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
,p_is_primary_key=>true
,p_duplicate_value=>true
,p_include_in_export=>false
,p_escape_on_http_output=>true
);
wwv_flow_api.create_region_column(
 p_id=>wwv_flow_api.id(24229613050176841)
,p_name=>'VIEW_NAME'
,p_source_type=>'DB_COLUMN'
,p_source_expression=>'VIEW_NAME'
,p_data_type=>'VARCHAR2'
,p_is_query_only=>false
,p_item_type=>'NATIVE_HIDDEN'
,p_display_sequence=>30
,p_attribute_01=>'Y'
,p_use_as_row_header=>false
,p_enable_sort_group=>false
,p_enable_control_break=>false
,p_enable_hide=>true
,p_is_primary_key=>true
,p_parent_column_id=>wwv_flow_api.id(50537663534307871)
,p_include_in_export=>false
);
wwv_flow_api.create_interactive_grid(
 p_id=>wwv_flow_api.id(24229533381176840)
,p_internal_uid=>56913867210051902
,p_is_editable=>false
,p_lazy_loading=>false
,p_requires_filter=>false
,p_show_nulls_as=>'-'
,p_select_first_row=>true
,p_fixed_row_height=>true
,p_pagination_type=>'SET'
,p_show_total_row_count=>false
,p_show_toolbar=>true
,p_toolbar_buttons=>'SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:SEARCH_COLUMN:SEARCH_FIELD:ACTIONS_MENU:RESET:SAVE'
,p_enable_save_public_report=>false
,p_enable_subscriptions=>true
,p_enable_flashback=>true
,p_define_chart_view=>true
,p_enable_download=>true
,p_enable_mail_download=>true
,p_fixed_header=>'PAGE'
,p_show_icon_view=>false
,p_show_detail_view=>false
);
wwv_flow_api.create_ig_report(
 p_id=>wwv_flow_api.id(24235023888198864)
,p_interactive_grid_id=>wwv_flow_api.id(24229533381176840)
,p_static_id=>'297034'
,p_type=>'PRIMARY'
,p_default_view=>'GRID'
,p_rows_per_page=>5
,p_show_row_number=>false
,p_settings_area_expanded=>true
);
wwv_flow_api.create_ig_report_view(
 p_id=>wwv_flow_api.id(24235163662198865)
,p_report_id=>wwv_flow_api.id(24235023888198864)
,p_view_type=>'GRID'
,p_stretch_columns=>true
,p_srv_exclude_null_values=>false
,p_srv_only_display_columns=>true
,p_edit_mode=>false
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(64777455109055817)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>7
,p_column_id=>wwv_flow_api.id(65171797779041950)
,p_is_visible=>false
,p_is_frozen=>false
,p_sort_order=>1
,p_sort_direction=>'ASC'
,p_sort_nulls=>'LAST'
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24238895936198890)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>6
,p_column_id=>wwv_flow_api.id(24230234074176847)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>80
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24238366310198888)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>5
,p_column_id=>wwv_flow_api.id(24230160014176846)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>40
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24237904572198886)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>4
,p_column_id=>wwv_flow_api.id(24230053385176845)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>80
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24237458319198885)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>2
,p_column_id=>wwv_flow_api.id(24229872623176844)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24236936773198883)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(24229787223176843)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>120
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24236415920198881)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>3
,p_column_id=>wwv_flow_api.id(24229679592176842)
,p_is_visible=>true
,p_is_frozen=>false
,p_width=>70
);
wwv_flow_api.create_ig_report_column(
 p_id=>wwv_flow_api.id(24235912179198876)
,p_view_id=>wwv_flow_api.id(24235163662198865)
,p_display_seq=>1
,p_column_id=>wwv_flow_api.id(24229613050176841)
,p_is_visible=>true
,p_is_frozen=>false
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(18462141010619334)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(18336791840600134)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(18462022841619334)
,p_plug_name=>'Preview File'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(18346340098600141)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(18461921516619334)
,p_plug_name=>'Wizard Progress'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(18324813764600130)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_list_id=>wwv_flow_api.id(18456512410619287)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(18379061872600162)
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(547315001934663)
,p_plug_name=>'Load file info'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(18346340098600141)
,p_plug_display_sequence=>20
,p_plug_new_grid_row=>false
,p_plug_grid_column_span=>8
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'HTML'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(18232034630750783)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(18462022841619334)
,p_button_name=>'DOWNLOAD'
,p_button_action=>'REDIRECT_URL'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(18398752605600175)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Download/View'
,p_button_position=>'BELOW_BOX'
,p_button_redirect_url=>'f?p=&APP_ID.:0:&APP_SESSION.:APPLICATION_PROCESS=DISPLAY_FILE:::FILE_ID:&P3_FILE_ID.'
,p_icon_css_classes=>'fa-download'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(18465221913619336)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(18462141010619334)
,p_button_name=>'CANCEL'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(18398658631600175)
,p_button_image_alt=>'Cancel'
,p_button_position=>'REGION_TEMPLATE_CLOSE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(18567042712697835)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(18462141010619334)
,p_button_name=>'NEXT'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(18398752605600175)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Next'
,p_button_position=>'REGION_TEMPLATE_NEXT'
,p_warn_on_unsaved_changes=>null
,p_icon_css_classes=>'fa-chevron-right'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(18465437364619336)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(18462141010619334)
,p_button_name=>'PREVIOUS'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(18398563205600174)
,p_button_image_alt=>'Previous'
,p_button_position=>'REGION_TEMPLATE_PREVIOUS'
,p_button_execute_validations=>'N'
,p_icon_css_classes=>'fa-chevron-left'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(26190535046083958)
,p_button_sequence=>40
,p_button_plug_id=>wwv_flow_api.id(547315001934663)
,p_button_name=>'ToggleAllSheets'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(18398658631600175)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'(Un)select All Sheets'
,p_button_position=>'RIGHT_OF_TITLE'
,p_button_execute_validations=>'N'
,p_warn_on_unsaved_changes=>null
,p_button_css_classes=>'toggle-all-sheets'
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(18467876590619338)
,p_branch_name=>'Next Page'
,p_branch_action=>'f?p=&APP_ID.:4:&SESSION.::&DEBUG.:4:P4_FILE_ID,P4_FILE_NAME,P4_SHEET_NAMES,P4_LAST_EXCEL_COLUMN_NAME,P4_CSV_FILE,P4_VIEW_NAME,P4_HEADER_ROW_FROM,P4_DATA_ROW_FROM,P4_DETERMINE_DATATYPE,P4_OBJECT_NAME,P4_HEADER_ROW_TILL,P4_OWNER,P4_DATA_ROW_TILL:&P3_FILE_ID.,&P3_FILE_NAME.,\&P3_SHEET_NAMES.\,&P3_LAST_EXCEL_COLUMN_NAME.,&P3_CSV_FILE.,&P3_VIEW_NAME.,&P3_HEADER_ROW_FROM.,&P3_DATA_ROW_FROM.,&P3_DETERMINE_DATATYPE.,&P3_OBJECT_NAME.,&P3_HEADER_ROW_TILL.,&P3_OWNER.,&P3_DATA_ROW_TILL.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(18567042712697835)
,p_branch_sequence=>20
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(18467231359619338)
,p_branch_name=>'Previous Page'
,p_branch_action=>'f?p=&APP_ID.:2:&SESSION.::&DEBUG.::P2_FILE_ID,P2_DETERMINE_DATATYPE:&P3_FILE_ID.,&P3_DETERMINE_DATATYPE.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'BEFORE_VALIDATION'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(18465437364619336)
,p_branch_sequence=>10
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(28420478765251772)
,p_name=>'P3_LOAD_FILE_INFO_HISTORY_COUNT'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'0'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
,p_item_comment=>'To prevent a batch of "Select Load Info History" dynamic actions.'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(25121684167718954)
,p_name=>'P3_DATA_ROW_TILL'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_prompt=>'Last Data Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_display_when=>'P3_CSV_FILE'
,p_display_when2=>'0'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_EQ_COND2'
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The last data row to process where empty means all starting from the first data row.'
,p_attribute_01=>'1'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24586568751603766)
,p_name=>'P3_OWNER'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(18462022841619334)
,p_item_default=>'&APPLICATION_OWNER.'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24446829194583140)
,p_name=>'P3_HEADER_ROW_TILL'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'1'
,p_prompt=>'Last Header Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'If the file contains a header this is the last row of the header. A value of 0 indicates no header. '
,p_attribute_01=>'0'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24285493337678748)
,p_name=>'P3_DETERMINE_DATATYPE'
,p_is_required=>true
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'2'
,p_prompt=>'Determine Data Type'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DETERMINE_DATATYPE'
,p_lov=>'.'||wwv_flow_api.id(65177840871101570)||'.'
,p_lov_display_null=>'YES'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_colspan=>3
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'Used when creating a table.'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24284742226677378)
,p_name=>'P3_DATA_ROW_FROM'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'2'
,p_prompt=>'First Data Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The first data row to process.'
,p_attribute_01=>'1'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24283909566674569)
,p_name=>'P3_HEADER_ROW_FROM'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'1'
,p_prompt=>'First Header Row'
,p_display_as=>'NATIVE_NUMBER_FIELD'
,p_cSize=>30
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'If the file contains a header this is the first row of the header. A value of 0 indicates no header. If there is a header the table field "Table Column (header)" will contain that information, otherwise the table field will be the same as the "File C'
||'olumn".'
,p_attribute_01=>'0'
,p_attribute_03=>'right'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24233805811176883)
,p_name=>'P3_OBJECT_NAME'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_prompt=>'Object Name'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The object loaded into.'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24231632248176861)
,p_name=>'P3_CSV_FILE'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(18462022841619334)
,p_use_cache_before_default=>'NO'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  case f.mime_type when ''text/csv'' then 1 else 0 end as is_csv',
'from    apex_application_temp_files f',
'where   f.name = :P3_FILE'))
,p_source_type=>'QUERY'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(24231201997176857)
,p_name=>'P3_VIEW_NAME'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_prompt=>'View Name'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The name of the view containing the load file info.'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'BOTH'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(18464925857619336)
,p_name=>'P3_LAST_EXCEL_COLUMN_NAME'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
,p_item_default=>'ZZ'
,p_prompt=>'Last Column (A,B,...)'
,p_display_as=>'NATIVE_TEXT_FIELD'
,p_cSize=>30
,p_cMaxlength=>4
,p_colspan=>2
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The last column you want to load into the database.'
,p_attribute_01=>'N'
,p_attribute_02=>'N'
,p_attribute_04=>'TEXT'
,p_attribute_05=>'NONE'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(18464520666619336)
,p_name=>'P3_SHEET_NAMES'
,p_is_required=>true
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(547315001934663)
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
,p_display_when=>'P3_CSV_FILE'
,p_display_when2=>'1'
,p_display_when_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_field_template=>wwv_flow_api.id(18398104910600173)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_help_text=>'The sheet(s) to upload from the spreadsheet file.'
,p_attribute_01=>'MULTI'
,p_attribute_06=>'Y'
,p_attribute_08=>'CIC'
,p_attribute_10=>'400'
,p_attribute_11=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(18464094053619336)
,p_name=>'P3_FILE_ID'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(18462022841619334)
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  f.id',
'from    apex_application_temp_files f',
'where   f.name = :P3_FILE'))
,p_source_type=>'QUERY'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(18463747376619336)
,p_name=>'P3_FILE'
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(18462022841619334)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(18229626675750759)
,p_name=>'P3_FILE_NAME'
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(18462022841619334)
,p_prompt=>'File'
,p_source=>wwv_flow_string.join(wwv_flow_t_varchar2(
'select  f.filename',
'from    apex_application_temp_files f',
'where   f.name = :P3_FILE'))
,p_source_type=>'QUERY'
,p_display_as=>'NATIVE_DISPLAY_ONLY'
,p_field_template=>wwv_flow_api.id(18397825820600171)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>'The name of the file uploaded.'
,p_attribute_01=>'Y'
,p_attribute_02=>'VALUE'
,p_attribute_04=>'Y'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(24233112470176876)
,p_name=>'Enable Items'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(18567042712697835)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(24233205143176877)
,p_event_id=>wwv_flow_api.id(24233112470176876)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'EnableItems();'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(18465633670619336)
,p_name=>'Cancel Dialog'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(18465221913619336)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(18466412409619337)
,p_event_id=>wwv_flow_api.id(18465633670619336)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_DIALOG_CANCEL'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(28421011329251777)
,p_name=>'CloseSheetNames'
,p_event_sequence=>20
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P3_SHEET_NAMES'
,p_bind_type=>'bind'
,p_bind_event_type=>'PLUGIN_BE.CTB.SELECT2|ITEM TYPE|slctclose'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(28421134282251778)
,p_event_id=>wwv_flow_api.id(28421011329251777)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'CloseSheetNames()',
''))
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(24231013957176855)
,p_name=>'Select Load Info History'
,p_event_sequence=>30
,p_triggering_element_type=>'REGION'
,p_triggering_region_id=>wwv_flow_api.id(50539956092307893)
,p_bind_type=>'bind'
,p_bind_event_type=>'NATIVE_IG|REGION TYPE|interactivegridselectionchange'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(24231120197176856)
,p_event_id=>wwv_flow_api.id(24231013957176855)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'SelectLoadFileInfo(this.data)'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(24448375144583156)
,p_name=>'DisableItems'
,p_event_sequence=>40
,p_bind_type=>'bind'
,p_bind_event_type=>'ready'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(24448496678583157)
,p_event_id=>wwv_flow_api.id(24448375144583156)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'SelectLoadFileInfo(null)',
''))
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(24449636703583168)
,p_name=>'Submit Page'
,p_event_sequence=>50
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(18567042712697835)
,p_triggering_condition_type=>'JAVASCRIPT_EXPRESSION'
,p_triggering_expression=>'apex.region("load_file_info_history").widget().interactiveGrid(''getViews'',''grid'').model._data.length > 0 && $v("P3_VIEW_NAME") == ""'
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(26184950970934273)
,p_event_id=>wwv_flow_api.id(24449636703583168)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_SUBMIT_PAGE'
,p_attribute_01=>'NEXT'
,p_attribute_02=>'Y'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(24449789761583170)
,p_event_id=>wwv_flow_api.id(24449636703583168)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if (confirm(apex.lang.getMessage(''ORACLE_TOOLS.LOAD_FILE_WITHOUT_HISTORY''))) {',
'  apex.submit({request:''NEXT'', showWait:true})',
'}',
''))
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(26190726922088356)
,p_name=>'Toggle All Sheets'
,p_event_sequence=>60
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(26190535046083958)
,p_condition_element=>'P3_SHEET_NAMES'
,p_triggering_condition_type=>'NULL'
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(26191132248088372)
,p_event_id=>wwv_flow_api.id(26190726922088356)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'EnableAllSheets()'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(26182296367934247)
,p_event_id=>wwv_flow_api.id(26190726922088356)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>'DisableAllSheets()'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(24232789161176873)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_region_id=>wwv_flow_api.id(50539956092307893)
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load file info history - Save Interactive Grid Data'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'ext_load_file_pkg.dml',
'( p_action => case ',
'                when :APEX$ROW_STATUS = ''C'' -- Note: In EA2 this has been changed from I to C for consistency with Tabular Forms  ',
'                then ''I''',
'                else :APEX$ROW_STATUS ',
'              end',
', p_view_name => :VIEW_NAME',
');'))
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
);
wwv_flow_api.component_end;
end;
/
