prompt --application/shared_components/navigation/lists/desktop_navigation_menu
begin
--   Manifest
--     LIST: Desktop Navigation Menu
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>84978882401008962
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(49678289944366462)
,p_name=>'Desktop Navigation Menu'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(49547406517366268)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Home'
,p_list_item_link_target=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:'
,p_list_item_icon=>'fa-home'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(47663521034496086)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Components'
,p_list_item_link_target=>'f?p=&APP_ID.:3000:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-shapes'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(47644788656437192)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'Wizards'
,p_list_item_link_target=>'f?p=&APP_ID.:1208:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-wizard'
,p_parent_list_item_id=>wwv_flow_api.id(47663521034496086)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'1208'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(33626210328214660)
,p_list_item_display_sequence=>50
,p_list_item_link_text=>'Text Messages (IG)'
,p_list_item_link_target=>'f?p=&APP_ID.:6:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-globe'
,p_parent_list_item_id=>wwv_flow_api.id(47663521034496086)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'6'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(49534480518366242)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Administration'
,p_list_item_link_target=>'f?p=&APP_ID.:10000:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-user-wrench'
,p_security_scheme=>wwv_flow_api.id(49554842526366311)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.component_end;
end;
/
