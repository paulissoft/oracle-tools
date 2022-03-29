prompt --application/pages/page_00002
begin
--   Manifest
--     PAGE: 00002
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
 p_id=>2
,p_user_interface_id=>wwv_flow_api.id(49557922988366350)
,p_name=>'Upload File'
,p_alias=>'UPLOAD-FILE'
,p_page_mode=>'MODAL'
,p_step_title=>'Upload File'
,p_autocomplete_on_off=>'OFF'
,p_javascript_code_onload=>wwv_flow_string.join(wwv_flow_t_varchar2(
'var button = parent.$(''.ui-dialog-titlebar-close''); //get the button',
'button.hide(); //hide the button'))
,p_step_template=>wwv_flow_api.id(49672540399366441)
,p_page_template_options=>'#DEFAULT#'
,p_required_role=>'MUST_NOT_BE_PUBLIC_USER'
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
,p_last_upd_yyyymmddhh24miss=>'20210607030013'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(49521351466347240)
,p_plug_name=>'Wizard Progress'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(49653656580366429)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_01'
,p_list_id=>wwv_flow_api.id(49521957934347272)
,p_plug_source_type=>'NATIVE_LIST'
,p_list_template_id=>wwv_flow_api.id(49599408472366397)
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(49521294662347240)
,p_plug_name=>'Upload File'
,p_region_template_options=>'#DEFAULT#:t-Region--scrollBody'
,p_plug_template=>wwv_flow_api.id(49632130246366418)
,p_plug_display_sequence=>10
,p_plug_display_point=>'BODY'
,p_plug_query_options=>'DERIVED_REPORT_COLUMNS'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_plug(
 p_id=>wwv_flow_api.id(49521147609347240)
,p_plug_name=>'Buttons'
,p_region_template_options=>'#DEFAULT#'
,p_plug_template=>wwv_flow_api.id(49641678504366425)
,p_plug_display_sequence=>10
,p_plug_display_point=>'REGION_POSITION_03'
,p_attribute_01=>'N'
,p_attribute_02=>'TEXT'
,p_attribute_03=>'Y'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(39558750158714795)
,p_button_sequence=>20
,p_button_plug_id=>wwv_flow_api.id(49521147609347240)
,p_button_name=>'FINISH'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(49579717739366384)
,p_button_is_hot=>'Y'
,p_button_image_alt=>'Finish'
,p_button_position=>'BELOW_BOX'
,p_warn_on_unsaved_changes=>null
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(49519268888347231)
,p_button_sequence=>10
,p_button_plug_id=>wwv_flow_api.id(49521147609347240)
,p_button_name=>'CANCEL'
,p_button_action=>'DEFINED_BY_DA'
,p_button_template_options=>'#DEFAULT#'
,p_button_template_id=>wwv_flow_api.id(49579811713366384)
,p_button_image_alt=>'Cancel'
,p_button_position=>'REGION_TEMPLATE_CLOSE'
);
wwv_flow_api.create_page_button(
 p_id=>wwv_flow_api.id(49518990539347231)
,p_button_sequence=>30
,p_button_plug_id=>wwv_flow_api.id(49521147609347240)
,p_button_name=>'NEXT'
,p_button_action=>'SUBMIT'
,p_button_template_options=>'#DEFAULT#:t-Button--iconRight'
,p_button_template_id=>wwv_flow_api.id(49579717739366384)
,p_button_image_alt=>'Next'
,p_button_position=>'REGION_TEMPLATE_NEXT'
,p_icon_css_classes=>'fa-chevron-right'
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(49517241088347225)
,p_branch_name=>'Next Page'
,p_branch_action=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.:3:P3_FILE,P3_OWNER:&P2_FILE.,&P2_OWNER.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(49518990539347231)
,p_branch_sequence=>20
);
wwv_flow_api.create_page_branch(
 p_id=>wwv_flow_api.id(39558891977714796)
,p_branch_name=>'Finish'
,p_branch_action=>'f?p=&APP_ID.:5:&SESSION.::&DEBUG.:5:P5_ACTION,P5_CSV_FILE,P5_DATA_ROW_FROM,P5_DATA_ROW_TILL,P5_DETERMINE_DATATYPE,P5_FILE_ID,P5_FILE_NAME,P5_HEADER_ROW_FROM,P5_HEADER_ROW_TILL,P5_LAST_EXCEL_COLUMN_NAME,P5_NEW_TABLE,P5_NR_ROWS,P5_OWNER,P5_SCHEMA,P5_SHEET_NAMES,P5_TABLE,P5_TABLE_VIEW,P5_VIEW_NAME:&P2_ACTION.,&P2_CSV_FILE.,&P2_DATA_ROW_FROM.,&P2_DATA_ROW_TILL.,&P2_DETERMINE_DATATYPE.,&P2_FILE_ID.,&P2_FILE_NAME.,&P2_HEADER_ROW_FROM.,&P2_HEADER_ROW_TILL.,&P2_LAST_EXCEL_COLUMN_NAME.,&P2_NEW_TABLE.,&P2_NR_ROWS.,&P2_OWNER.,&P2_SCHEMA.,&P2_SHEET_NAMES.,&P2_TABLE.,&P2_TABLE_VIEW.,&P2_VIEW_NAME.&success_msg=#SUCCESS_MSG#'
,p_branch_point=>'AFTER_PROCESSING'
,p_branch_type=>'REDIRECT_URL'
,p_branch_when_button_id=>wwv_flow_api.id(39558750158714795)
,p_branch_sequence=>30
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(49519536925347231)
,p_name=>'P2_FILE'
,p_is_required=>true
,p_item_sequence=>20
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_use_cache_before_default=>'NO'
,p_prompt=>'File'
,p_display_as=>'NATIVE_FILE'
,p_cSize=>30
,p_tag_attributes=>'accept=".csv,.xls,.xlsx,.xlsm,.xlsb,.ods"'
,p_field_template=>wwv_flow_api.id(49580644524366388)
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
,p_attribute_12=>'NATIVE'
,p_item_comment=>'text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,application/vnd.ms-excel.sheet.binary.macroEnabled.12,application/vnd.oasis.opendocument.spreadsheet'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(43528045992383383)
,p_name=>'P2_OWNER'
,p_item_sequence=>50
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_item_default=>'&APPLICATION_OWNER.'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
,p_item_comment=>'The owner can be used to use another owner than this application''s owner, which is the parsing schema of this application.'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(39558252777714790)
,p_name=>'P2_NR_ROWS'
,p_item_sequence=>220
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(39558137348714789)
,p_name=>'P2_HEADER_ROW_TILL'
,p_item_sequence=>120
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(39558041290714788)
,p_name=>'P2_DATA_ROW_TILL'
,p_item_sequence=>140
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38191255991576514)
,p_name=>'P2_FILE_NAME'
,p_item_sequence=>60
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38190954894574614)
,p_name=>'P2_CSV_FILE'
,p_item_sequence=>70
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38190701708572748)
,p_name=>'P2_VIEW_NAME'
,p_item_sequence=>80
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38190312898570188)
,p_name=>'P2_LAST_EXCEL_COLUMN_NAME'
,p_item_sequence=>90
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38190005530567743)
,p_name=>'P2_SHEET_NAMES'
,p_item_sequence=>100
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38189741054565903)
,p_name=>'P2_HEADER_ROW_FROM'
,p_item_sequence=>110
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38189419035563944)
,p_name=>'P2_DATA_ROW_FROM'
,p_item_sequence=>130
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38189152767561791)
,p_name=>'P2_DETERMINE_DATATYPE'
,p_item_sequence=>150
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_prompt=>'Determine Datatype'
,p_display_as=>'NATIVE_SELECT_LIST'
,p_named_lov=>'LOV_DETERMINE_DATATYPE'
,p_lov=>'.'||wwv_flow_api.id(2800629473864989)||'.'
,p_lov_display_null=>'YES'
,p_cHeight=>1
,p_begin_on_new_line=>'N'
,p_field_template=>wwv_flow_api.id(49580644524366388)
,p_item_template_options=>'#DEFAULT#'
,p_lov_display_extra=>'NO'
,p_attribute_01=>'NONE'
,p_attribute_02=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38188866959555387)
,p_name=>'P2_NEW_TABLE'
,p_item_sequence=>160
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_use_cache_before_default=>'NO'
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38188593113552734)
,p_name=>'P2_ACTION'
,p_item_sequence=>170
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38188278729547679)
,p_name=>'P2_TABLE'
,p_item_sequence=>180
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38187926395542825)
,p_name=>'P2_TABLE_VIEW'
,p_item_sequence=>210
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38187695099540758)
,p_name=>'P2_SCHEMA'
,p_item_sequence=>190
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(38178476949386401)
,p_name=>'P2_FILE_ID'
,p_item_sequence=>200
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'N'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(31159156704662955)
,p_name=>'P2_APPLICATION_CONTEXT'
,p_item_sequence=>40
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_display_as=>'NATIVE_HIDDEN'
,p_attribute_01=>'Y'
,p_item_comment=>'The application context can be used to set context from the calling application.'
);
wwv_flow_api.create_page_item(
 p_id=>wwv_flow_api.id(2805854263924601)
,p_name=>'P2_EXPERT_MODE'
,p_is_required=>true
,p_item_sequence=>30
,p_item_plug_id=>wwv_flow_api.id(49521294662347240)
,p_item_default=>'0'
,p_prompt=>'Expert Mode?'
,p_display_as=>'NATIVE_YES_NO'
,p_field_template=>wwv_flow_api.id(49580644524366388)
,p_item_template_options=>'#DEFAULT#'
,p_attribute_01=>'APPLICATION'
);
wwv_flow_api.create_page_computation(
 p_id=>wwv_flow_api.id(31159300212662956)
,p_computation_sequence=>10
,p_computation_item=>'APPLICATION_CONTEXT'
,p_computation_point=>'BEFORE_HEADER'
,p_computation_type=>'EXPRESSION'
,p_computation_language=>'PLSQL'
,p_computation=>':P2_APPLICATION_CONTEXT'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(49518843916347230)
,p_name=>'Cancel Dialog'
,p_event_sequence=>10
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(49519268888347231)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(49518048608347227)
,p_event_id=>wwv_flow_api.id(49518843916347230)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_DIALOG_CANCEL'
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(36429747088450502)
,p_name=>'Submit Page'
,p_event_sequence=>20
,p_triggering_element_type=>'BUTTON'
,p_triggering_button_id=>wwv_flow_api.id(39558750158714795)
,p_bind_type=>'bind'
,p_bind_event_type=>'click'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(36429850365450503)
,p_event_id=>wwv_flow_api.id(36429747088450502)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'N'
,p_action=>'NATIVE_JAVASCRIPT_CODE'
,p_attribute_01=>wwv_flow_string.join(wwv_flow_t_varchar2(
'if (confirm(apex.lang.getMessage(''ORACLE_TOOLS.FINISH_LOAD_FILE''))) {',
'  apex.submit({request:''FINISH'', showWait:true})',
'}'))
);
wwv_flow_api.create_page_da_event(
 p_id=>wwv_flow_api.id(2805910236924602)
,p_name=>'EnableExpertMode'
,p_event_sequence=>30
,p_triggering_element_type=>'ITEM'
,p_triggering_element=>'P2_EXPERT_MODE'
,p_condition_element=>'P2_EXPERT_MODE'
,p_triggering_condition_type=>'IN_LIST'
,p_triggering_expression=>'1,Y'
,p_bind_type=>'bind'
,p_bind_event_type=>'change'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(2806165896924604)
,p_event_id=>wwv_flow_api.id(2805910236924602)
,p_event_result=>'FALSE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_DISABLE'
,p_affected_elements_type=>'BUTTON'
,p_affected_button_id=>wwv_flow_api.id(49518990539347231)
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(2806016839924603)
,p_event_id=>wwv_flow_api.id(2805910236924602)
,p_event_result=>'TRUE'
,p_action_sequence=>10
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_ENABLE'
,p_affected_elements_type=>'BUTTON'
,p_affected_button_id=>wwv_flow_api.id(49518990539347231)
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(2806550030924608)
,p_event_id=>wwv_flow_api.id(2805910236924602)
,p_event_result=>'FALSE'
,p_action_sequence=>20
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_HIDE'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P2_DETERMINE_DATATYPE'
);
wwv_flow_api.create_page_da_action(
 p_id=>wwv_flow_api.id(2806464789924607)
,p_event_id=>wwv_flow_api.id(2805910236924602)
,p_event_result=>'TRUE'
,p_action_sequence=>20
,p_execute_on_page_init=>'Y'
,p_action=>'NATIVE_SHOW'
,p_affected_elements_type=>'ITEM'
,p_affected_elements=>'P2_DETERMINE_DATATYPE'
);
wwv_flow_api.create_page_process(
 p_id=>wwv_flow_api.id(39558401650714791)
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
'  if :P2_DETERMINE_DATATYPE is not null',
'  then',
'    l_object_info_rec.determine_datatype := :P2_DETERMINE_DATATYPE;  ',
'  end if;',
'  ext_load_file_pkg.load',
'  ( p_apex_file => :P2_FILE',
'  , p_owner => :P2_OWNER',
'  , p_object_info_rec => l_object_info_rec -- in/out',
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
,p_process_clob_language=>'PLSQL'
,p_error_display_location=>'INLINE_IN_NOTIFICATION'
,p_process_when_button_id=>wwv_flow_api.id(39558750158714795)
,p_process_success_message=>'Number of rows processed: &P2_NR_ROWS.'
);
wwv_flow_api.component_end;
end;
/
