prompt --application/shared_components/navigation/breadcrumbs/breadcrumb
begin
--   Manifest
--     MENU: Breadcrumb
--   Manifest End
wwv_flow_api.component_begin (
 p_version_yyyy_mm_dd=>'2020.10.01'
,p_release=>'20.2.0.00.20'
,p_default_workspace_id=>2601326064169245
,p_default_application_id=>138
,p_default_id_offset=>80521331112734834
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_menu(
 p_id=>wwv_flow_api.id(24242232835253777)
,p_name=>'Breadcrumb'
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(26289903106183061)
,p_parent_id=>wwv_flow_api.id(26260516993173975)
,p_short_name=>'Wizards'
,p_link=>'f?p=&APP_ID.:1208:&SESSION.'
,p_page_id=>1208
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(26260516993173975)
,p_short_name=>'Components'
,p_link=>'f?p=&APP_ID.:3000:&SESSION.'
,p_page_id=>3000
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(24387473471254003)
,p_short_name=>'Administration'
,p_link=>'f?p=&APP_ID.:10000:&SESSION.'
,p_page_id=>10000
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(24242502870253777)
,p_short_name=>'Home'
,p_link=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.'
,p_page_id=>1
);
wwv_flow_api.component_end;
end;
/
