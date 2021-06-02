prompt --application/shared_components/logic/application_items/file_id
begin
wwv_flow_api.create_flow_item(
 p_id=>wwv_flow_api.id(47330249059552267)
,p_name=>'FILE_ID'
,p_protection_level=>'N'
,p_item_comment=>'The temporary file id (APEX_APPLICATION_TEMP_FILES).'
);
end;
/
