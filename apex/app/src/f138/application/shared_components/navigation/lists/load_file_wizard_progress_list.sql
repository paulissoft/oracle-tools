prompt --application/shared_components/navigation/lists/load_file_wizard_progress_list
begin
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(51140846239494349)
,p_name=>'Load File Wizard Progress List'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(51141972218494381)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Upload File'
,p_list_item_link_target=>'f?p=&APP_ID.:2:&SESSION.::&DEBUG.::::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(51146733695494396)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Preview File'
,p_list_item_link_target=>'f?p=&APP_ID.:3:&SESSION.::&DEBUG.::::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(51153420423494400)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Load'
,p_list_item_link_target=>'f?p=&APP_ID.:4:&SESSION.::&DEBUG.::::'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(52691152645029611)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'Load Summary'
,p_list_item_link_target=>'f?p=&APP_ID.:5:&SESSION.::&DEBUG.::::'
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
