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
,p_default_id_offset=>107828709909037496
,p_default_owner=>'ORACLE_TOOLS'
);
wwv_flow_api.create_menu(
 p_id=>wwv_flow_api.id(37748891160289343)
,p_name=>'Breadcrumb'
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(39796561431218627)
,p_parent_id=>wwv_flow_api.id(39767175318209541)
,p_short_name=>'Wizards'
,p_link=>'f?p=&APP_ID.:1208:&SESSION.'
,p_page_id=>1208
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(39767175318209541)
,p_short_name=>'Components'
,p_link=>'f?p=&APP_ID.:3000:&SESSION.'
,p_page_id=>3000
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(37894131796289569)
,p_short_name=>'Administration'
,p_link=>'f?p=&APP_ID.:10000:&SESSION.'
,p_page_id=>10000
);
wwv_flow_api.create_menu_option(
 p_id=>wwv_flow_api.id(37749161195289343)
,p_short_name=>'Home'
,p_link=>'f?p=&APP_ID.:1:&APP_SESSION.::&DEBUG.'
,p_page_id=>1
);
wwv_flow_api.component_end;
end;
/
