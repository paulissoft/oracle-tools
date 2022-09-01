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
,p_default_id_offset=>139229780191799327
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(82179707047338188)
,p_name=>'Desktop Navigation Menu'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82048823620337994)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Home'
,p_list_item_link_target=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.:'
,p_list_item_icon=>'fa-home'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(80164938137467812)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Components'
,p_list_item_link_target=>'f?p=&APP_ID.:3000:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-shapes'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(80146205759408918)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'Wizards'
,p_list_item_link_target=>'f?p=&APP_ID.:1208:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-wizard'
,p_parent_list_item_id=>wwv_flow_api.id(80164938137467812)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'1208'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(66127627431186386)
,p_list_item_display_sequence=>50
,p_list_item_link_text=>'Text Messages (IG)'
,p_list_item_link_target=>'f?p=&APP_ID.:6:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-globe'
,p_parent_list_item_id=>wwv_flow_api.id(80164938137467812)
,p_list_item_current_type=>'COLON_DELIMITED_PAGE_LIST'
,p_list_item_current_for_pages=>'6'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82035897621337968)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Administration'
,p_list_item_link_target=>'f?p=&APP_ID.:10000:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-user-wrench'
,p_security_scheme=>wwv_flow_api.id(82056259629338037)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.component_end;
end;
/
