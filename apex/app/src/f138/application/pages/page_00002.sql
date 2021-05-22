prompt --application/pages/page_00002
begin
wwv_flow_api.create_page(
 p_id=>2
,p_user_interface_id=>wwv_flow_api.id(51104881185475271)
,p_name=>'Upload File'
,p_page_mode=>'MODAL'
,p_step_title=>'Upload File'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var button = parent.$(''.ui-dialog-titlebar-close''); //get the button',
'button.hide(); //hide the button'))
,p_step_template=>wwv_flow_api.id(50990263774475180)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>wwv_flow_api.id(51107961647475310)
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>',
'    This is the first step of the wizard to upload a spreadsheet file into the database.    ',
'</p>',
'<p>',
'    If the defaults suit you, you may press the Finish button to immediately load the file and go to the last step.',
'</p>',
'<p>',
'The defaults are:',
'<ul>',
'    <li>only the first sheet will be loaded (only relevant for a non-CSV file)</li>',
'    <li>the first sheet name (or file name for a CSV) is used to create a table with the same name (if it does not already exist). Thus file ''Example.xlsx'' with first sheet ''Sheet 1'' will load into a table named "Sheet 1". For a CSV file ''Example 1.c'
||'sv'' it will be "Example 1.csv".</li>',
'    <li>the owner of the table is the application owner - ORACLE_TOOLS - by default</li>',
'    <li>the last sheet column that may be loaded is ZZ</li>',
'    <li>the first row is the header row and these header column names are used to create the table (if necessary)</li>',
'    <li>the datatype of each column is determined by inspecting the data</li>',
'    <li>for a CSV file the character set is Windows CP1252</li>',
'</ul>       ',
'</p>'))
,p_last_updated_by=>'ADMIN'
,p_last_upd_yyyymmddhh24miss=>'20210511123314'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(51141452707494381)
,p_plug_name=>'Wizard Progress'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(51009147593475192)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_list_id=>wwv_flow_api.id(51140846239494349)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(51063395701475224)
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(51141509511494381)
,p_plug_name=>'Upload File'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(51030673927475203)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(51141656564494381)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(51021125669475196)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(61104054015126826)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(51141656564494381)
,p_button_name=>'FINISH'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(51083086434475237)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Finish'
,p_button_position=>'BELOW_BOX'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(51143535285494390)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(51141656564494381)
,p_button_name=>'CANCEL'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(51082992460475237)
,p_button_image_alt=>'Cancel'
,p_button_position=>'REGION_TEMPLATE_CLOSE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(51143813634494390)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(51141656564494381)
,p_button_name=>'NEXT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(51083086434475237)
,p_button_image_alt=>'Next'
,p_button_position=>'REGION_TEMPLATE_NEXT'
,p_icon_css_classes=>'fa-chevron-right'
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(51145563085494396)
,p_branch_name=>'Next Page'
,p_branch_action=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.:3:P3_FILE,P3_OWNER:&P2_FILE.,&P2_OWNER.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(51143813634494390)
,p_branch_sequence=>20
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(61103912196126825)
,p_branch_name=>'Finish'
,p_branch_action=>'f?p=&APP_ID.:5:&SESSION.::&DEBUG.:5:P5_ACTION,P5_CSV_FILE,P5_DATA_ROW_FROM,P5_DATA_ROW_TILL,P5_DETERMINE_DATATYPE,P5_FILE_ID,P5_FILE_NAME,P5_HEADER_ROW_FROM,P5_HEADER_ROW_TILL,P5_LAST_EXCEL_COLUMN_NAME,P5_NEW_TABLE,P5_NR_ROWS,P5_OWNER,P5_SCHEMA,P5_SHEET_NAMES,P5_TABLE,P5_TABLE_VIEW,P5_VIEW_NAME:&P2_ACTION.,&P2_CSV_FILE.,&P2_DATA_ROW_FROM.,&P2_DATA_ROW_TILL.,&P2_DETERMINE_DATATYPE.,&P2_FILE_ID.,&P2_FILE_NAME.,&P2_HEADER_ROW_FROM.,&P2_HEADER_ROW_TILL.,&P2_LAST_EXCEL_COLUMN_NAME.,&P2_NEW_TABLE.,&P2_NR_ROWS.,&P2_OWNER.,&P2_SCHEMA.,&P2_SHEET_NAMES.,&P2_TABLE.,&P2_TABLE_VIEW.,&P2_VIEW_NAME.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(61104054015126826)
,p_branch_sequence=>30
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(51143267248494390)
,p_name=>'P2_FILE'
,p_is_required=>true
,p_item_sequence=>10
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_use_cache_before_default=>'NO'
,p_prompt=>'File'
,p_display_as=>'NATIVE_FILE'
,p_cSize=>30
,p_tag_attributes=>'accept=".csv,.xls,.xlsx,.xlsm,.xlsb,.ods"'
,p_field_template=>wwv_flow_api.id(51082159649475233)
,p_item_template_options=>'#DEFAULT#'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Choose the spreadsheet file to upload with possible file types:',
'<ul>    ',
'    <li>CSV files</li>',
'    <li>Microsoft XLS, XLSX, XLSM or XLSB files</li>',
'    <li>Open Office ODS files</li>',
'</ul>',
''))
,p_attribute_01=>'APEX_APPLICATION_TEMP_FILES'
,p_attribute_09=>'SESSION'
,p_attribute_10=>'N'
,p_item_comment=>'text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,application/vnd.ms-excel.sheet.binary.macroEnabled.12,application/vnd.oasis.opendocument.spreadsheet'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(57134758181458238)
,p_name=>'P2_OWNER'
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'&APPLICATION_OWNER.'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(61104551396126831)
,p_name=>'P2_NR_ROWS'
,p_item_sequence=>190
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(61104666825126832)
,p_name=>'P2_HEADER_ROW_TILL'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'1'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(61104762883126833)
,p_name=>'P2_DATA_ROW_TILL'
,p_item_sequence=>120
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'0'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62471548182265107)
,p_name=>'P2_FILE_NAME'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62471849279267007)
,p_name=>'P2_CSV_FILE'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62472102465268873)
,p_name=>'P2_VIEW_NAME'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62472491275271433)
,p_name=>'P2_LAST_EXCEL_COLUMN_NAME'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62472798643273878)
,p_name=>'P2_SHEET_NAMES'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62473063119275718)
,p_name=>'P2_HEADER_ROW_FROM'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'1'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62473385138277677)
,p_name=>'P2_DATA_ROW_FROM'
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'0'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62473651406279830)
,p_name=>'P2_DETERMINE_DATATYPE'
,p_item_sequence=>130
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'1'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62473937214286234)
,p_name=>'P2_NEW_TABLE'
,p_item_sequence=>140
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_use_cache_before_default=>'NO'
,p_item_default=>'0'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62474211060288887)
,p_name=>'P2_ACTION'
,p_item_sequence=>150
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_item_default=>'I'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62474525444293942)
,p_name=>'P2_TABLE'
,p_item_sequence=>160
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62474877778298796)
,p_name=>'P2_TABLE_VIEW'
,p_item_sequence=>180
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62475109074300863)
,p_name=>'P2_SCHEMA'
,p_item_sequence=>170
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(62484327224455220)
,p_name=>'P2_FILE_ID'
,p_item_sequence=>170
,p_item_plug_id=>wwv_flow_api.id(51141509511494381)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(51143960257494391)
,p_name=>'Cancel Dialog'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(51143535285494390)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(51144755565494394)
,p_event_id=>wwv_flow_api.id(51143960257494391)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_DIALOG_CANCEL'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(4567845496912435)
,p_name=>'Submit Page'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(61104054015126826)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(4567948773912436)
,p_event_id=>wwv_flow_api.id(4567845496912435)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if (confirm(apex.lang.getMessage(''ORACLE_TOOLS.FINISH_LOAD_FILE''))) {',
'  apex.submit({request:''FINISH'', showWait:true})',
'}'))
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(61104402523126830)
,p_process_sequence=>10
,p_process_point=>'AFTER_SUBMIT'
,p_process_type=>'NATIVE_PLSQL'
,p_process_name=>'Load File'
,p_process_sql_clob=>wwv_flow_string.join(wwv_flow_t_varchar2(
'declare',
'  l_owner all_objects.owner%type;',
'  l_object_info_rec ext_load_file_pkg.t_object_info_rec;',
'  l_apex_file_id apex_application_temp_files.id%type;',
'  l_apex_file_name apex_application_temp_files.filename%type;',
'  l_csv_file natural;',
'  l_action varchar2(1);',
'  l_new_table natural;',
'  l_nr_rows natural;',
'begin ',
'  ext_load_file_pkg.load',
'  ( p_apex_file => :P2_FILE',
'  , p_owner => :P2_OWNER',
'  , p_object_info_rec => l_object_info_rec',
'  , p_apex_file_id => l_apex_file_id',
'  , p_apex_file_name => l_apex_file_name',
'  , p_csv_file => l_csv_file',
'  , p_action => l_action',
'  , p_new_table => l_new_table',
'  , p_nr_rows => l_nr_rows',
'  );',
'  :P2_FILE_ID := l_apex_file_id;',
'  :P2_FILE_NAME := l_apex_file_name;',
'  :P2_CSV_FILE := l_csv_file;  ',
'  :P2_VIEW_NAME := l_object_info_rec.view_name;',
'  :P2_LAST_EXCEL_COLUMN_NAME := l_object_info_rec.last_excel_column_name;',
'  :P2_SHEET_NAMES := l_object_info_rec.sheet_names;',
'  :P2_HEADER_ROW_FROM := l_object_info_rec.header_row_from;',
'  :P2_HEADER_ROW_TILL := l_object_info_rec.header_row_till;',
'  :P2_DATA_ROW_FROM := l_object_info_rec.data_row_from;',
'  :P2_DATA_ROW_TILL := l_object_info_rec.data_row_till;',
'  :P2_DETERMINE_DATATYPE := l_object_info_rec.determine_datatype;  ',
'  :P2_ACTION := l_action;',
'  :P2_NEW_TABLE := l_new_table;',
'  if l_new_table = 1',
'  then',
'    :P2_SCHEMA := null;',
'    :P2_TABLE_VIEW := null;',
'    ext_load_file_pkg.parse_object_name',
'    ( p_fq_object_name => l_object_info_rec.object_name',
'    , p_owner => l_owner',
'    , p_object_name => :P2_TABLE',
'    );',
'    :P2_TABLE := ''"'' || :P2_TABLE || ''"'';',
'  else',
'    ext_load_file_pkg.parse_object_name',
'    ( p_fq_object_name => l_object_info_rec.object_name',
'    , p_owner => :P2_SCHEMA',
'    , p_object_name => :P2_TABLE_VIEW',
'    );',
'    :P2_TABLE_VIEW := ''"'' || :P2_TABLE_VIEW || ''"'';',
'    :P2_OWNER := null;    ',
'  end if;',
'  :P2_NR_ROWS := l_nr_rows;',
'end;'))
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_api.id(61104054015126826)
,p_process_success_message=>'Number of rows processed: &P2_NR_ROWS.'
);
end;
/
