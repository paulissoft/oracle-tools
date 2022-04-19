prompt --application/shared_components/navigation/lists/ut_wizard_progress
begin
--   Manifest
--     LIST: UT - Wizard Progress
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>107828709909037496
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(39796727896218628)
,p_name=>'UT - Wizard Progress'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(39797071527218628)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Step 1'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-check-circle'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(39797446028218628)
,p_list_item_display_sequence=>15
,p_list_item_link_text=>'Step 2'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-cloud'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(39797832242218628)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Step 3'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-comment'
,p_list_item_current_type=>'ALWAYS'
,p_list_item_current_for_pages=>'1112'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(39798181385218628)
,p_list_item_display_sequence=>25
,p_list_item_link_text=>'Step 4'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-dashboard'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
);
wwv_flow_api.component_end;
end;
/
