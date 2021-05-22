prompt --application/shared_components/navigation/lists/ut_wizard_progress
begin
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(53031854233404442)
,p_name=>'UT - Wizard Progress'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53032197864404442)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Step 1'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-check-circle'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53032572365404442)
,p_list_item_display_sequence=>15
,p_list_item_link_text=>'Step 2'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-cloud'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53032958579404442)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Step 3'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-comment'
,p_list_item_current_type=>'ALWAYS'
,p_list_item_current_for_pages=>'1112'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53033307722404442)
,p_list_item_display_sequence=>25
,p_list_item_link_text=>'Step 4'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-dashboard'
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
);
end;
/
