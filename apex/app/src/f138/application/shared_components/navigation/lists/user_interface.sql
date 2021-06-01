prompt --application/shared_components/navigation/lists/user_interface
begin
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(47373294065621521)
,p_name=>'User Interface'
,p_list_status=>'PUBLIC'
,p_required_patch=>wwv_flow_api.id(47395567990621599)
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(47372945712621520)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Theme Style Selection'
,p_list_item_link_target=>'f?p=&APP_ID.:10010:&SESSION.::&DEBUG.:10010:::'
,p_list_item_icon=>'fa-paint-brush'
,p_list_text_01=>'Set the default application look and feel'
,p_required_patch=>wwv_flow_api.id(47395567990621599)
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
