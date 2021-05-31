prompt --application/shared_components/logic/application_items/fsp_language_preference
begin
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(5741031868758951)
,p_name=>'FSP_LANGUAGE_PREFERENCE'
,p_scope=>'GLOBAL'
,p_protection_level=>'S'
);
end;
/
