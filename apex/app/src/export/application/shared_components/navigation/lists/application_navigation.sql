prompt --application/shared_components/navigation/lists/application_navigation
begin
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(20311687578427798)
,p_name=>'Application Navigation'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(20311871302427799)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Components'
,p_list_item_link_target=>'f?p=&APP_ID.:3000:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-shapes'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(20312450040431968)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Wizards'
,p_list_item_link_target=>'f?p=&APP_ID.:1208:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-wizard'
,p_parent_list_item_id=>wwv_flow_api.id(20311871302427799)
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
