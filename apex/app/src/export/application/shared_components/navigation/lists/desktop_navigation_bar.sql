prompt --application/shared_components/navigation/lists/desktop_navigation_bar
begin
--   Manifest
--     LIST: Desktop Navigation Bar
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
 p_id=>wwv_flow_api.id(82059690697338078)
,p_name=>'Desktop Navigation Bar'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82038547644337969)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Show Help'
,p_list_item_link_target=>'f?p=&APP_ID.:&APP_PAGE_ID.:&SESSION.::&DEBUG.::SHOW_HELP:1:'
,p_list_item_icon=>'fa-question-circle-o'
,p_list_item_disp_cond_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_list_item_disp_condition=>'SHOW_HELP'
,p_list_item_disp_condition2=>'1'
,p_required_patch=>wwv_flow_api.id(82057055297338040)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(79951396821213131)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Hide Help'
,p_list_item_link_target=>'f?p=&APP_ID.:&APP_PAGE_ID.:&SESSION.::&DEBUG.::SHOW_HELP:0:'
,p_list_item_icon=>'fa-question-circle-o'
,p_list_item_disp_cond_type=>'VAL_OF_ITEM_IN_COND_NOT_EQ_COND2'
,p_list_item_disp_condition=>'SHOW_HELP'
,p_list_item_disp_condition2=>'0'
,p_required_patch=>wwv_flow_api.id(82057055297338040)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82037792637337969)
,p_list_item_display_sequence=>40
,p_list_item_link_text=>'About Page'
,p_list_item_link_target=>'f?p=&APP_ID.:10020:&SESSION.::&DEBUG.:10020:::'
,p_list_item_icon=>'fa-info-circle-o'
,p_required_patch=>wwv_flow_api.id(82057055297338040)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82037438265337969)
,p_list_item_display_sequence=>50
,p_list_item_link_text=>'&APP_USER.'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-user'
,p_list_text_02=>'has-username'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82036991461337969)
,p_list_item_display_sequence=>60
,p_list_item_link_text=>'---'
,p_list_item_link_target=>'separator'
,p_parent_list_item_id=>wwv_flow_api.id(82037438265337969)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(82036598564337969)
,p_list_item_display_sequence=>70
,p_list_item_link_text=>'Sign Out'
,p_list_item_link_target=>'&LOGOUT_URL.'
,p_list_item_icon=>'fa-sign-out'
,p_parent_list_item_id=>wwv_flow_api.id(82037438265337969)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(70105881147287156)
,p_list_item_display_sequence=>80
,p_list_item_link_text=>'Language'
,p_list_item_link_target=>'#'
,p_list_item_icon=>'fa-globe'
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(70106977186296905)
,p_list_item_display_sequence=>90
,p_list_item_link_text=>'English'
,p_list_item_link_target=>'javascript:apex.submit(''en'')'
,p_parent_list_item_id=>wwv_flow_api.id(70105881147287156)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(70107328532298975)
,p_list_item_display_sequence=>100
,p_list_item_link_text=>unistr('Fran\00E7ais')
,p_list_item_link_target=>'javascript:apex.submit(''fr'')'
,p_parent_list_item_id=>wwv_flow_api.id(70105881147287156)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.component_end;
end;
/
