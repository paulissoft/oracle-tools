prompt --application/shared_components/logic/application_items
begin
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(57261601841160683)
,p_name=>'APPLICATION_OWNER'
,p_protection_level=>'I'
,p_item_comment=>'The application owner at login.'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(51172539346544639)
,p_name=>'FILE_ID'
,p_protection_level=>'N'
,p_item_comment=>'The temporary file id (APEX_APPLICATION_TEMP_FILES).'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(5741031868758951)
,p_name=>'FSP_LANGUAGE_PREFERENCE'
,p_scope=>'GLOBAL'
,p_protection_level=>'S'
);
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(53203957404324204)
,p_name=>'SHOW_HELP'
,p_protection_level=>'S'
);
end;
/
