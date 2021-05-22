prompt --application/shared_components/navigation/lists/ut_components
begin
wwv_flow_api.create_list(
 p_id=>wwv_flow_api.id(53002517394395361)
,p_name=>'UT - Components'
,p_list_status=>'PUBLIC'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53003663722395362)
,p_list_item_display_sequence=>10
,p_list_item_link_text=>'Activity Timeline'
,p_list_item_link_target=>'f?p=&APP_ID.:1406:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-history'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53004019949395362)
,p_list_item_display_sequence=>20
,p_list_item_link_text=>'Alert'
,p_list_item_link_target=>'f?p=&APP_ID.:1202:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-alert'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53004414160395362)
,p_list_item_display_sequence=>30
,p_list_item_link_text=>'Badges List'
,p_list_item_link_target=>'f?p=&APP_ID.:1304:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-badge-list'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53004850441395363)
,p_list_item_display_sequence=>50
,p_list_item_link_text=>'Breadcrumb'
,p_list_item_link_target=>'f?p=&APP_ID.:3810:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-breadcrumb'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53005253510395363)
,p_list_item_display_sequence=>60
,p_list_item_link_text=>'Buttons'
,p_list_item_link_target=>'f?p=&APP_ID.:1500:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-button'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53005684838395363)
,p_list_item_display_sequence=>70
,p_list_item_link_text=>'Button Group'
,p_list_item_link_target=>'f?p=&APP_ID.:1204:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-button-group'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53006000155395363)
,p_list_item_display_sequence=>80
,p_list_item_link_text=>'Button Container Region'
,p_list_item_link_target=>'f?p=&APP_ID.:1250:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-button-container'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53006422759395363)
,p_list_item_display_sequence=>90
,p_list_item_link_text=>'Calendars'
,p_list_item_link_target=>'f?p=&APP_ID.:1800:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-calendar'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53006887673395363)
,p_list_item_display_sequence=>100
,p_list_item_link_text=>'Cards'
,p_list_item_link_target=>'f?p=&APP_ID.:3100:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-cards'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53007204265395363)
,p_list_item_display_sequence=>110
,p_list_item_link_text=>'Carousel'
,p_list_item_link_target=>'f?p=&APP_ID.:1205:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-carousel'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53007672646395363)
,p_list_item_display_sequence=>120
,p_list_item_link_text=>'Charts'
,p_list_item_link_target=>'f?p=&APP_ID.:1902:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-bar-chart'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53008034149395363)
,p_list_item_display_sequence=>130
,p_list_item_link_text=>'Collapsible'
,p_list_item_link_target=>'f?p=&APP_ID.:1206:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-collapsible'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53008400765395364)
,p_list_item_display_sequence=>140
,p_list_item_link_text=>'Comments'
,p_list_item_link_target=>'f?p=&APP_ID.:1405:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-comments-o'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53008868675395364)
,p_list_item_display_sequence=>150
,p_list_item_link_text=>'Data Tables and Reports'
,p_list_item_link_target=>'f?p=&APP_ID.:3400:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-table'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53009201196395364)
,p_list_item_display_sequence=>160
,p_list_item_link_text=>'Forms'
,p_list_item_link_target=>'f?p=&APP_ID.:1600:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-forms'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53009641547395364)
,p_list_item_display_sequence=>170
,p_list_item_link_text=>'Help Text'
,p_list_item_link_target=>'f?p=&APP_ID.:1903:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>' fa-question-circle-o'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53010014410395364)
,p_list_item_display_sequence=>180
,p_list_item_link_text=>'Hero'
,p_list_item_link_target=>'f?p=&APP_ID.:1203:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-hero'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53010496162395364)
,p_list_item_display_sequence=>190
,p_list_item_link_text=>'Lists'
,p_list_item_link_target=>'f?p=&APP_ID.:1300:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-list'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53010866186395364)
,p_list_item_display_sequence=>195
,p_list_item_link_text=>'List View'
,p_list_item_link_target=>'f?p=&APP_ID.:1700:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-list'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53011225507395365)
,p_list_item_display_sequence=>200
,p_list_item_link_text=>'Map Chart'
,p_list_item_link_target=>'f?p=&APP_ID.:1904:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-map-o'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53011678595395365)
,p_list_item_display_sequence=>205
,p_list_item_link_text=>'Menu Bar'
,p_list_item_link_target=>'f?p=&APP_ID.:1305:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-tabs'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53012080677395365)
,p_list_item_display_sequence=>208
,p_list_item_link_text=>'Menu Popup'
,p_list_item_link_target=>'f?p=&APP_ID.:1306:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-list-alt'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53012490242395365)
,p_list_item_display_sequence=>210
,p_list_item_link_text=>'Modal Dialogs'
,p_list_item_link_target=>'f?p=&APP_ID.:1906:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-layout-modal-header'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53012878966395365)
,p_list_item_display_sequence=>220
,p_list_item_link_text=>'PL/SQL Dynamic Content'
,p_list_item_link_target=>'f?p=&APP_ID.:1908:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-dynamic-content'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53013219838395365)
,p_list_item_display_sequence=>230
,p_list_item_link_text=>'Region Display Selector'
,p_list_item_link_target=>'f?p=&APP_ID.:1907:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-tabs'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53013698260395365)
,p_list_item_display_sequence=>235
,p_list_item_link_text=>'Responsive Tables'
,p_list_item_link_target=>'f?p=&APP_ID.:1710:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-table'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53014000279395365)
,p_list_item_display_sequence=>240
,p_list_item_link_text=>'Standard Region'
,p_list_item_link_target=>'f?p=&APP_ID.:1201:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-layout-header'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53014461770395365)
,p_list_item_display_sequence=>250
,p_list_item_link_text=>'Static Content'
,p_list_item_link_target=>'f?p=&APP_ID.:1905:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-code'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53014890192395365)
,p_list_item_display_sequence=>255
,p_list_item_link_text=>'Tabs'
,p_list_item_link_target=>'f?p=&APP_ID.:1907:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-tabs'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'NEVER'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53015289924395366)
,p_list_item_display_sequence=>260
,p_list_item_link_text=>'Title Bar Region'
,p_list_item_link_target=>'f?p=&APP_ID.:1207:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-breadcrumb'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53015645427395366)
,p_list_item_display_sequence=>270
,p_list_item_link_text=>'Tree'
,p_list_item_link_target=>'f?p=&APP_ID.:1901:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-tree-org'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53016014734395366)
,p_list_item_display_sequence=>280
,p_list_item_link_text=>'URL'
,p_list_item_icon=>'fa-link'
,p_list_item_disp_cond_type=>'NEVER'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53002828370395362)
,p_list_item_display_sequence=>290
,p_list_item_link_text=>'Value Attribute Pairs Report'
,p_list_item_link_target=>'f?p=&APP_ID.:1403:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-th-list'
,p_required_patch=>wwv_flow_api.id(53049750917420620)
,p_list_item_current_type=>'TARGET_PAGE'
);
wwv_flow_api.create_list_item(
 p_id=>wwv_flow_api.id(53003287865395362)
,p_list_item_display_sequence=>300
,p_list_item_link_text=>'Wizards'
,p_list_item_link_target=>'f?p=&APP_ID.:1208:&SESSION.::&DEBUG.::::'
,p_list_item_icon=>'fa-wizard'
,p_list_item_current_type=>'TARGET_PAGE'
);
end;
/
